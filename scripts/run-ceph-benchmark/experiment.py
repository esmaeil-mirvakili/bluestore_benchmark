import os

block_sizes = ['']
block_splits = []
io_depths = [256]
exp_parameters = [
    [0, 1],
    [5 * 1000 * 1000],
    [5 * 1024 * 1024],
    [200 * 1024],
    [200 * 1024],
    [30],
    [1]
]
output_path = '~/results'


def main():
    os.system('sudo rm -f codel_*')
    os.system('sudo rm -f dump-fio-bench-*')
    os.system('sudo rm -rf randwrite-*')
    settings = [""]
    for params in exp_parameters:
        new_settings = []
        for setting in settings:
            for param in params:
                setting += str(param) + '\n'
                new_settings.append(setting)
        settings = new_settings

    for block_split in block_splits:
        for block_size in block_sizes:
            for io_depth in io_depths:
                for i,setting in enumerate(settings):
                    with open('codel.settings', 'w') as file:
                        file.write(setting)
                    os.system(f'sudo ./run-fio-queueing-delay.sh {io_depth} randwrite {block_size} 0 0 0 1 /dev/sdc {block_split}')
                    os.system(f'sudo mkdir -p {output_path}/{block_split}/{i}')
                    os.system(f'sudo mv codel_* {output_path}/{block_split}/{i}')
                    os.system(f'sudo mv dump-fio-bench-* {output_path}/{block_split}/{i}')


if __name__ == "__main__":
    main()