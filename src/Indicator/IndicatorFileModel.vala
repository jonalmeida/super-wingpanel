// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2010-2012 Canonical Ltd
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

  Authored by canonical.com
***/

namespace SuperWingpanel.Backend {

    public class IndicatorFileModel {
        private Gee.HashMap<Indicator.Object, string> indicator_map;

        public IndicatorFileModel (Services.Settings settings) {
            indicator_map = new Gee.HashMap<Indicator.Object, string> ();

            // Indicators we don't want to load
            string skip_list = Environment.get_variable ("UNITY_PANEL_INDICATORS_SKIP") ?? "";

            if (skip_list == "all") {
                warning ("Skipping all indicator loading");
                return;
            }

            foreach (string blocked_indicator in settings.blacklist) {
                skip_list += "," + blocked_indicator;
                debug ("Blacklisting %s", blocked_indicator);
            }

            debug ("Blacklisted Indicators: %s", skip_list);

            var indicators_to_load = new Gee.ArrayList<string> ();
            var dir = File.new_for_path (Build.INDICATORDIR);
            debug ("Indicator Directory: %s", dir.get_path ());

            try {
                var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME,
                                                         FileQueryInfoFlags.NONE, null);

                FileInfo file_info;

                while ((file_info = enumerator.next_file (null)) != null) {
                    string leaf = file_info.get_name ();

                    if (leaf in skip_list) {
                        warning ("SKIP LOADING: %s", leaf);
                        continue;
                    }

                    if (leaf.has_suffix (".so"))
                        indicators_to_load.add (leaf);
                }
            } catch (Error err) {
                error ("Unable to read indicators: %s", err.message);
            }

            foreach (string leaf in indicators_to_load)
                load_indicator (dir.get_child (leaf).get_path (), leaf);
        }

        public Gee.Collection<Indicator.Object> get_indicators () {
            return indicator_map.keys;
        }

        public string get_indicator_name (Indicator.Object indicator) {
            return indicator_map.get (indicator);
        }

        private void load_indicator (string filename, string leaf) {
            debug ("LOADING: %s", leaf);

            var indicator = new Indicator.Object.from_file (filename);

            if (indicator is Indicator.Object)
                indicator_map.set (indicator, leaf);
            else
                critical ("Unable to load %s", filename);
        }
    }
}
