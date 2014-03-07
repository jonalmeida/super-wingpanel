// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2013 Wingpanel Developers
    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/


namespace SuperWingpanel
{

    public class WingpanelApp : Granite.Application
    {
        static int monitor_number;

        private PanelController panel;

        construct
        {
            build_data_dir = Build.DATADIR;
            build_pkg_data_dir = Build.PKGDATADIR;
            build_release_name = Build.RELEASE_NAME;
            build_version = Build.VERSION;
            build_version_info = Build.VERSION_INFO;

            program_name = "Super Wingpanel";
            exec_name = "super-wingpanel";
            application_id = "net.launchpad.wingpanel";
        }


        static new const OptionEntry[] options = {
            { "debug", 'd', 0, OptionArg.NONE, out DEBUG, "Enable debug logging", null },
            { "monitor", 'm', 0, OptionArg.INT, ref monitor_number, "Specify Monitor", "<monitor number>" },
            { null }
        };

        protected override void startup () {
            base.startup ();
            debug ("Starting up...");

            if (get_windows () == null)
            {
                panel = new PanelController (this, monitor_number);
            }
        }
        
        public static int main (string[] args) {
            monitor_number = -1;
            try 
            {
                var opt_context = new OptionContext ("");
                opt_context.set_help_enabled (true);
                opt_context.add_main_entries (options, null);
                opt_context.parse (ref args);
            } catch (OptionError e) {
                stdout.printf ("error: %s\n", e.message);
                stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
                return 0;
            }
            return new WingpanelApp ().run (args);
        }
    }
}
