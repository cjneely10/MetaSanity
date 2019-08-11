# cython: language_level=3

import luigi
import os
import subprocess


class BioMetaDBConstants:
    BIOMETADB = "BIOMETADB"
    DB_NAME = "--db_name"
    TABLE_NAME = "--table_name"
    ALIAS = "--alias"


class GetDBDMCall(luigi.Task):
    cancel_autocommit = luigi.BoolParameter()
    table_name = luigi.Parameter()
    alias = luigi.Parameter()
    calling_script_path = luigi.Parameter()
    db_name = luigi.Parameter()
    directory_name = luigi.Parameter()
    data_file = luigi.Parameter()
    added_flags = luigi.ListParameter(default=[])
    storage_string = luigi.Parameter(default="")

    def run(self):
        if not os.path.exists(str(self.data_file)):
            return
        if not bool(self.cancel_autocommit):
            print("Storing %s to database.........." % str(self.storage_string))
            if not os.path.exists(str(self.db_name)):
                subprocess.run(
                    [
                        "python3",
                        str(self.calling_script_path),
                        "INIT",
                        "-n",
                        str(self.db_name),
                        "-t",
                        str(self.table_name).lower(),
                        "-d",
                        str(self.directory_name),
                        "-f",
                        str(self.data_file),
                        "-a",
                        str(self.alias).lower(),
                        *self.added_flags,
                    ],
                    check=True,
                )
                print("Database storage complete!")
            elif os.path.exists(str(self.db_name)) and not os.path.exists(os.path.join(str(self.db_name), "classes", str(self.table_name).lower() + ".json")):
                subprocess.run(
                    [
                        "python3",
                        str(self.calling_script_path),
                        "CREATE",
                        "-c",
                        str(self.db_name),
                        "-t",
                        str(self.table_name).lower(),
                        "-a",
                        str(self.alias).lower(),
                        "-f",
                        str(self.data_file),
                        "-d",
                        str(self.directory_name),
                        *self.added_flags,
                    ],
                    check=True,
                )
                print("Database storage complete!")
            elif os.path.exists(str(self.db_name)) and os.path.exists(os.path.join(str(self.db_name), "classes", str(self.table_name).lower() + ".json")):
                subprocess.run(
                    [
                        "python3",
                        str(self.calling_script_path),
                        "UPDATE",
                        "-c",
                        str(self.db_name),
                        "-t",
                        str(self.table_name).lower(),
                        "-a",
                        str(self.alias).lower(),
                        "-f",
                        str(self.data_file),
                        "-d",
                        str(self.directory_name),
                        *self.added_flags,
                    ],
                    check=True,
                )
                print("Database storage complete!")
            else:
                return None
