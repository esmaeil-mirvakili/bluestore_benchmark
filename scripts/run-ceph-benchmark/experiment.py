import os
import sys
import yaml
import math
import re
import subprocess

output_path = '/users/esmaeil/results'


def size_split(sizes, size_mix):
    split = ''
    for size, mix in zip(sizes, size_mix):
        split += f'{size}/{mix}:'
    return split[:-1]


def size2bytes(size):
    if size[-1].isalpha():
        if size[-1] == 'k':
            return int(size[:-1]) * 1024
        if size[-1] == 'm':
            return int(size[:-1]) * 1024 * 1024
        if size[-1] == 'g':
            return int(size[:-1]) * 1024 * 1024 * 1024
        return int(size[:-1])
    else:
        return int(size)


def time2ns(time):
    if time[-1].isalpha():
        if time[-2:] == 'ns':
            return math.floor(float(time[:-2]))
        if time[-2:] == 'us':
            return math.floor(float(time[:-2]) * 1000)
        if time[-2:] == 'ms':
            return math.floor(float(time[:-2]) * 1000 * 1000)
        return math.floor(float(time[:-1]) * 1000 * 1000 * 1000)
    else:
        return int(time)


def main(experiment_setup_yaml):
    if experiment_setup_yaml is None:
        experiment_setup_yaml = 'experiment_setups.yaml'
    os.system('sudo rm -f *.csv')
    os.system('sudo rm -f dump-fio-bench-*')
    os.system('sudo rm -rf randwrite-*')
    with open(experiment_setup_yaml) as yaml_file:
        setups = yaml.load(yaml_file, Loader=yaml.FullLoader)
        i = 0
        while i < len(setups['experiments']):
            setup = setups['experiments'][i]
            with open('codel.settings', 'w') as file:
                lines = [
                    '0',
                    time2ns(setup['target']),
                    time2ns(setup['window']),
                    size2bytes(setup['starting_throttle']),
                    size2bytes(setup['min_throttle']),
                    setup['beta'],
                    '1' if setup['smart_inc'] else '0',
                    '1' if setup['adaptive_target'] else '0',
                    setup['slow_codel_freq'],
                    time2ns(setup['max_target_latency']),
                    time2ns(setup['min_target_latency']),
                    '1' if setup['outlier_detection'] else '0',
                    time2ns(setup['range']),
                    time2ns(setup['config_latency_threshold']),
                    setup['size_threshold'],
                    setup['rnd_std_dev']
                ]
                file.writelines([str(line)+'\n' for line in lines])
            block_size2 = None
            if setup['one_job']:
                split = size_split(setup['sizes'], setup['size_mix'])
                block_size = '4k'
                if 100 in setup['size_mix']:
                    split = ''
                    for size, mix in zip(setup['sizes'], setup['size_mix']):
                        if mix == 100:
                            block_size = size
                            break
            else:
                block_size = setup['sizes'][0]
                block_size2 = setup['sizes'][1]
                split = ''
            lines = []
            io_max = setup['io_depth']
            if block_size2 is not None:
                with open('fio_multi_job_write.fio') as fio_write:
                    lines = fio_write.readlines()
            else:
                with open('fio_write.fio') as fio_write:
                    lines = fio_write.readlines()
            with open('fio_write_edited.fio', 'w') as fio_write:
                for line in lines:
                    if len(split) > 0:
                        line = re.sub(r'bs=.*', f'bssplit={split}', line)
                    else:
                        if block_size2 is None:
                            line = re.sub(r'bs=.*', f'bs={block_size}', line)
                        else:
                            line = re.sub(r'bs= *\{1\}', f'bs={block_size}', line)
                            line = re.sub(r'bs= *\{2\}', f'bs={block_size2}', line)
                    line = re.sub(r'rw=.*', f'rw={setup["op_type"]}', line)
                    line = re.sub(r'runtime=.*', f'runtime={setup["run_time"]}', line)
                    line = re.sub(r'startdelay=.*', f'startdelay={setup["run_time"]}', line)
                    line = re.sub(r'iodepth=.*', f'iodepth={setup["io_depth"]}', line)
                    fio_write.write(line)
                if 'mix_read' in setup:
                    fio_write.write(f'\nrwmixread={setup["mix_read"]}')
            if block_size2 is None:
                with open('fio_prefill_rbdimage.fio') as fio_prefill:
                    lines = fio_prefill.readlines()
            else:
                with open('fio_multi_job_prefill_rbdimage.fio') as fio_prefill:
                    lines = fio_prefill.readlines()
            with open('fio_prefill_rbdimage_edited.fio', 'w') as fio_prefill:
                for line in lines:
                    if len(split) > 0:
                        line = re.sub(r'bs=.*', f'bssplit={split}', line)
                    else:
                        if block_size2 is None:
                            line = re.sub(r'bs=.*', f'bs={block_size}', line)
                        else:
                            line = re.sub(r'bs= *\{1\}', f'bs={block_size}', line)
                            line = re.sub(r'bs= *\{2\}', f'bs={block_size2}', line)
                    line = re.sub(r'rw=.*', f'rw=randwrite', line)
                    line = re.sub(r'runtime=.*', f'runtime={setup["prefill_time"]}', line)
                    line = re.sub(r'startdelay=.*', f'startdelay={setup["prefill_time"]}', line)
                    line = re.sub(r'iodepth=.*', f'iodepth={io_max}', line)
                    fio_prefill.write(line)
                # if 'mix_read' in setup:
                #     fio_prefill.write(f'\nrwmixread={setup["mix_read"]}')
            active = '1' if setup['codel'] else '0'
            ssd_thread_num = setup['ssd_thread_num']
            cmd = f'sudo ./run-fio-queueing-delay.sh {active} {ssd_thread_num}'
            print(cmd)
            # os.system(cmd)
            p = subprocess.Popen([cmd], shell=True)
            try:
                p.wait(2 * int(setup["run_time"]) + int(setup["prefill_time"]))
            except subprocess.TimeoutExpired:
                p.kill()
                os.system('sudo pkill -f ceph')
                continue
            i += 1
            path = os.path.join(output_path, setup["name"])
            os.system(f'sudo mkdir -p {path}')
            os.system(f'sudo mv *.csv {path}')
            os.system(f'sudo mv dump-fio-bench* {path}')
            with open(os.path.join(path, 'codel_settings.yaml'), 'w') as codel_settings:
                yaml.dump(setup, codel_settings)


if __name__ == "__main__":
    experiments_setups = None
    if len(sys.argv) > 1:
        print(sys.argv)
        experiments_setups = sys.argv[1]
    main(experiments_setups)
