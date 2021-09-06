import yaml
import os


def main():
    setups = []
    for index in range(5):
        for op_type in ['randwrite']:
            for read_mix in [0]:
                for sizes in [['4k', '64k']]:
                    for percentages in [[100, 0], [50, 50], [0, 100]]:
                        for beta in [0.01, 0.1, 0.5, 1, 2, 5, 7, 10, 15, 20, 100]:
                            for start_point in ['5ms']:
                                name = f'{op_type}_'
                                if read_mix > 0:
                                    name += f'{read_mix}_read_'
                                for i, size in enumerate(sizes):
                                    name += f'{percentages[i]}_{sizes[i]}_'
                                name += 'write_'
                                name += f'beta_{beta}_{index}'
                                setup = {
                                    'name': name,
                                    'sizes': sizes,
                                    'size_mix': percentages,
                                    'one_job': True,
                                    'io_depth': 1024,
                                    'codel': False,
                                    'target': start_point,
                                    'window': '50ms',
                                    'beta': beta,
                                    'starting_throttle': '200k',
                                    'min_throttle': '10k',
                                    'smart_inc': True,
                                    'adaptive_target': True,
                                    'slow_codel_freq': 10,
                                    'max_target_latency': '1000ms',
                                    'min_target_latency': '1ms',
                                    'run_time': 300,
                                    'prefill_time': 600,
                                    'outlier_detection': False,
                                    'range': '1ms',
                                    'config_latency_threshold': '10ms',
                                    'size_threshold': 100,
                                    'rnd_std_dev': 5,
                                    'op_type': op_type
                                }
                                if read_mix > 0:
                                    setup['mix_read'] = read_mix
                                setups.append(setup)
    with open('experiment_setups.yaml', 'w') as yaml_file:
        yaml.dump({'experiments': setups}, yaml_file)
    os.system('sudo python3 experiment.py')


if __name__ == "__main__":
    main()
