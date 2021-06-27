import os
import sys
import yaml
import math

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
        for setup in setups['experiments']:
            with open('codel.settings', 'w') as file:
                lines = [
                    '1' if setup['codel'] else '0',
                    time2ns(setup['target']),
                    time2ns(setup['window']),
                    size2bytes(setup['starting_throttle']),
                    size2bytes(setup['min_throttle']),
                    setup['beta'],
                    '1',
                    '1' if setup['only_4k'] else '0',
                    '1' if setup['adaptive_target'] else '0',
                    setup['slow_codel_freq'],
                    setup['step_size'],
                    '1' if setup['smart_inc'] else '0',
                    setup['agg_threshold'],
                    setup['norm_threshold'],
                    setup['window_size'],
                    setup['lat_normalization_factor'],
                    setup['bw_noise_threshold'],
                    setup['lat_noise_threshold'],
                    '1' if setup['optimize_using_target'] else '0',
                    '1' if setup['throughput_outlier_detection'] else '0',
                    setup['delta_threshold'],
                ]
                file.writelines([str(line)+'\n' for line in lines])
            split = size_split(setup['sizes'], setup['size_mix'])
            block_size = '4k'
            if 100 in setup['size_mix']:
                split = ''
                for size, mix in zip(setup['sizes'], setup['size_mix']):
                    if mix == 100:
                        block_size = size
                        break
            cmd = f'sudo ./run-fio-queueing-delay.sh {setup["io_depth"]} randwrite {block_size} /dev/sdc {setup["run_time"]} {setup["prefill_time"]} {split}'
            print(cmd)
            os.system(cmd)
            path = os.path.join(output_path, setup["name"])
            os.system(f'sudo mkdir -p {path}')
            os.system(f'sudo mv *.csv {path}')
            os.system(f'sudo mv dump-fio-bench-* {path}')
            with open(os.path.join(path, 'codel_settings.yaml'), 'w') as codel_settings:
                yaml.dump(setup, codel_settings)


if __name__ == "__main__":
    experiments_setups = None
    if len(sys.argv) > 1:
        print(sys.argv)
        experiments_setups = sys.argv[1]
    main(experiments_setups)
