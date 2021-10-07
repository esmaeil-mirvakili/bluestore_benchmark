import os
import sys
import yaml
import math
import re
import subprocess

output_path = '/users/esmaeil/results'


def export_config(name, value):
    # os.system(f'export {name}="{value}"')
    os.environ[name] = str(value)


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

            export_config('CODEL', 1 if setup['codel'] else 0)
            export_config('TARGET', time2ns(setup['target']))
            export_config('FAST_INTERVAL', time2ns(setup['fast_interval']))
            export_config('SLOW_INTERVAL', time2ns(setup['slow_interval']))
            export_config('SLOP_TARGET', setup['slop_target'])
            export_config('STARTING_BUDGET', setup['starting_budget'])
            export_config('MIN_BUDGET', setup['min_budget'])
            export_config('MAX_TARGET_LATENCY', setup['max_target_latency'])
            export_config('MIN_TARGET_LATENCY', setup['min_target_latency'])
            export_config('REGRESSION_HISTORY_SIZE', setup['regression_history_size'])

            export_config('FIO_CONFIG', setup['fio_config'])
            export_config('FIO_PREFILL_CONFIG', setup['fio_prefill_config'])

            cmd = f'sudo ./run-fio-queueing-delay.sh'
            os.system(cmd)
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
