import argparse


def run_command(args):
    pass


def parse_args():
    arg_parser = argparse.ArgumentParser(prog='python prepare_experiment.py')
    arg_parser.add_argument('command',
                            metavar='command',
                            type=str,
                            choices=[
                                'generate',
                                'info',
                            ],
                            help='the command that needs to be executed.')

    subparsers = arg_parser.add_subparsers(help='sub-command help')

    # gen exp
    experiment_gen_parser = subparsers.add_parser('generate', help='generates an experiment')
    experiment_gen_parser.add_argument('-i', '--index',
                                       action='store_const',
                                       default=0,
                                       nargs=1,
                                       type=int,
                                       help='the index of experiment in the config file (0 ... n)')

    # gen exp
    experiment_info_parser = subparsers.add_parser('info', help='information about experiments')
    experiment_info_parser.add_argument('-n', '--number',
                                        action='store_true',
                                        help='show number of available experiments in the config file')
    experiment_info_parser.add_argument('-l', '--list',
                                        action='store_true',
                                        help='list the names of available experiments in the config file')


    return arg_parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    run_command(args)
