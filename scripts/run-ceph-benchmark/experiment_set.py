import yaml
import os


def main():
    setups = []
    vanilla_done = []
    codel_done = []
    sfcodel_done = []
    for codel in [False, True]:
        for fio_config in [('fio_write_4K_16.fio', 'prefill/fio_prefill_rbdimage_4K_2048.fio'), ('fio_write_4K_64.fio', 'prefill/fio_prefill_rbdimage_4K_2048.fio'), ('fio_write_4K_128.fio', 'prefill/fio_prefill_rbdimage_4K_2048.fio'), ('fio_write_4K_256.fio', 'prefill/fio_prefill_rbdimage_4K_2048.fio'), ('fio_write_4K_512.fio', 'prefill/fio_prefill_rbdimage_4K_2048.fio'), ('fio_write_4K_1024.fio', 'prefill/fio_prefill_rbdimage_4K_2048.fio')]:
            for slow_interval in ['500ms', '0ms']:
                for target_slope in [0.1, 0.5, 1, 5, 10, 20]:
                    for target in ['5ms', '10ms']:
                        fio_name = fio_config[0].replace('fio_', '').replace('.fio', '').strip()
                        if codel:
                            if slow_interval == '0ms':
                                name = f'codel_target_{target}'
                                codel_name = f'{target}_{fio_config[0]}'
                                if codel_name in codel_done:
                                    continue
                                codel_done.append(codel_name)
                            else:
                                sfcodel_name = f'{target_slope}_{fio_config[0]}'
                                if sfcodel_name in sfcodel_done:
                                    continue
                                codel_done.append(sfcodel_name)
                                name = f'sfcodel_target_slope_{target_slope}'
                        else:
                            if fio_config[0] in vanilla_done:
                                continue
                            vanilla_done.append(fio_config[0])
                            name = 'vanilla'
                        name += f'_{fio_name}'
                        setup = {
                            'name': name,
                            'fio_config': fio_config[0],
                            'fio_prefill_config': fio_config[1],
                            'codel': codel,
                            'target': target,
                            'fast_interval': '50ms',
                            'slow_interval': slow_interval,
                            'slop_target': target_slope,
                            'starting_budget': '200k',
                            'min_budget': '10k',
                            'max_target_latency': '30ms',
                            'min_target_latency': '1ms',
                            'regression_history_size': 100,
                        }
                        setups.append(setup)
    with open('experiment_setups.yaml', 'w') as yaml_file:
        yaml.dump({'experiments': setups}, yaml_file)
    os.system('sudo python3 experiment.py')


if __name__ == "__main__":
    main()
