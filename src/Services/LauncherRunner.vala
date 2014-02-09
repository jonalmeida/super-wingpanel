// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//  
//  Copyright (C) 2012-2013 Wingpanel Developers
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

public class SuperWingpanel.Services.LauncherRunner {
    private Settings settings;
    
    public LauncherRunner (Settings settings) {
        this.settings = settings;
    }

    public bool execute () {
        debug ("Starting launcher");

        // Parse Arguments
        string[] argvp = null;
        string launcher_command = settings.default_launcher;

        try {
            Shell.parse_argv (launcher_command, out argvp);
        } catch (ShellError error) {
            warning ("Not passing any args to %s : %s", launcher_command, error.message);
            argvp = {launcher_command, null}; // fix value in case it's corrupted
        }

        // Check if the program is actually there
        string? launcher = Environment.find_program_in_path (argvp[0]);

        if (launcher != null) {
            // Spawn process asynchronously
            try {
                var flags = SpawnFlags.SEARCH_PATH
                          | SpawnFlags.DO_NOT_REAP_CHILD
                          | SpawnFlags.STDOUT_TO_DEV_NULL;

                Pid process_id;
                Process.spawn_async (null, argvp, null, flags, null, out process_id);

                // Add watch or otherwise the process will become a zombie
                ChildWatch.add (process_id, dispose_process);
            } catch (SpawnError err) {
                warning ("Couldn't spawn launcher: %s", err.message);
                return_val_if_reached (false);
            }
        } else {
            run_fallback_launcher ();
        }

        return true;
    }

    private static void dispose_process (Pid pid, int status) {
        Process.close_pid (pid);
    }

    private static void run_fallback_launcher () {
        Granite.Services.System.open_uri ("file:///usr/share/applications");
    }
}
