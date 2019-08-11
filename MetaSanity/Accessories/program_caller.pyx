# cython: language_level=3
import traceback

"""
Script handles program calls and minimizes the amount of code that needs to be written

"""


class ProgramCaller:
    def __init__(self, programs, flags, errors, _help, classes={None: None}):
        """ ProgramCaller is used for when a script has multiple possible sub-programs available.
            Wrapper functionality is available to ensure database or file system integrity

            Example:
                from arg_parse import ArgParse
                from program_caller import ProgramCaller

                def add_file(fasta_file, data_type):
                    ...

                def remove_file(fasta_file):
                    ...

                if __name__ == "__main__":
                    programs = {	"ADD":			add_file,
                                    "REMOVE":       remove_file
                    }
                    flags = {		"ADD":			("fasta_file", "data_type"),
                                    "REMOVE":       ("fasta_file",),
                    }
                    errors = {		FileNotFoundError:		"Incorrect database called",
                    }
                    _help = {	    "ADD":		"Program for adding files to database",
                                    "REMOVE":   "Program for removing files from db"
                    }

                    args_list = [
                        [["-f", "--fasta_file"],
                            {"help": "File to pass", "default": "None"}],
                        [["-d", "--data_type"],
                            {"help": "Type of data (fasta or fastq)", "require": True}],
                    ]

                    ap = ArgParse(args_list,
                                description=ArgParse.description_builder("dbdm:\tManaging database operations.",
                                    _help, flags))
                    pc = ProgramCaller(classes=classes, programs=programs, flags=flags, errors=errors, _help=_help)

                    pc.run(ap.args)

                ## Note that the names of the arguments that each function takes are THE SAME as
                ## the arguments that are passed from ArgParse

        :param classes: (Dict[str, class])		Class mappings
        :param programs: (Dict[str, callable])	Program name: function mapping
        :param flags: (Dict[str, tuple])		Flag mapping program_name: (needed flags,)
        :param errors: (Dict[str, str])			Error string to print by error type
        """
        self.classes = classes
        self.programs = programs
        self.flags = flags
        self.errors = errors
        self.errors["INCORRECT_FLAGS"] = "Pass all necessary flags:"
        self._help = _help

    def error(self, error_type, program, message):
        """ Function called to handle error

        :param message: (str)       Message passed from exception
        :param error_type: (str)	Key for type of error
        :param program: (str)	Name of program that was called
        """
        if type(error_type) == str:
            if "flags" in error_type or "FLAGS" in error_type:
                print()
                print(" ERROR " + self.errors["INCORRECT_FLAGS"], "--" + " --".join(self.flags[program]))
        else:
            print()
            print(" ERROR " + self.errors[error_type] + ":\t" + str(message))
            exit(1)
        if program in self._help.keys():
            print()
            print(" " + program + ": " + self._help[program])
            print(traceback.print_exc())
        print()
        exit(1)

    def mapper(self, program, debug=False):
        """ Function maps the name of a program with its given function and returns function call
            Catches errors that may arise and returns user-defined response

        :param debug: (bool)    Set debug options to display full error Traceback
        :param program: (str)	Name of program to use in programs dict to call function
        :return function:
        """
        if not debug:
            try:
                return self.programs[program](**self.flags_dict)
            except AssertionError as e:
                print(e)
                exit(1)
            except Exception as e:
                try:
                    print(self.error(type(e), program, e))
                except KeyError:
                    print("An untracked exception has occurred\n Class: {}\n {}".format(type(e), e))
        else:
            return self.programs[program](**self.flags_dict)

    def flag_check(self, program, ap_args_object):
        """ Function checks if required flags were set for a given program

        :param ap_args_object: (ArgParse)   ArgParse object
        :param program: (str)	Name of program
        :return bool:
        """
        try:
            self.flags_dict = {flag: vars(ap_args_object)[flag] for flag in self.flags[program]}
        except KeyError as e:
            print(" ERROR: Invalid program name", str(e))
            exit(1)
        for flag in self.flags[program]:
            if self.flags_dict[flag] == "" or self.flags_dict[flag] is None:
                return flag
        return None

    def run(self, args, debug=False):
        """ Primary function to call ProgramCaller and to run the script

        :param debug: (bool)    Set debug options to display full error Traceback
        :param args: (ArgParse.args)	ArgParse.args object
        """
        program = args.program
        failed = self.flag_check(program, args)
        if not failed:
            self.mapper(program, debug)
        else:
            self.error("INCORRECT_FLAGS", program, failed)
