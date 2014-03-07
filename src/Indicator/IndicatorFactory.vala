// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2013 Wingpanel Developers
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

public class SuperWingpanel.Backend.IndicatorFactory : Object, IndicatorLoader {
    private Gee.Collection<IndicatorIface> indicators;
    private string[] settings_blacklist;

    public IndicatorFactory (string[] settings_blacklist) {
        this.settings_blacklist = settings_blacklist;
    }

    public Gee.Collection<IndicatorIface> get_indicators () {
        if (indicators == null) {
            indicators = new Gee.LinkedList<IndicatorIface> ();
            load_indicators ();
        }

        return indicators.read_only_view;
    }

    private void load_indicators () {
        // Fetch list of indicators that should not be loaded
        string skip_list = Environment.get_variable ("UNITY_PANEL_INDICATORS_SKIP") ?? "";

        if (skip_list == "all") {
            warning ("Skipping all indicator loading");
            return;
        }

        foreach (string blocked_indicator in settings_blacklist)
            skip_list += "," + blocked_indicator;

        debug ("Blacklisted Indicators: %s", skip_list);

        // Legacy indicator libraries
        load_indicators_from_dir (Build.INDICATORDIR, true, skip_list);

        // Ng indicators
        load_indicators_from_dir ("/usr/share/unity/indicators", false, skip_list);
    }

    private void load_indicators_from_dir (string dir_path, bool legacy_libs_only, string skip_list) {
        try {
            var dir = File.new_for_path (dir_path);
            var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME,
                                                     FileQueryInfoFlags.NONE, null);
            FileInfo file_info;

            while ((file_info = enumerator.next_file (null)) != null) {
                string name = file_info.get_name ();

                if (name in skip_list)
                    continue;

                load_indicator (dir, legacy_libs_only, name);
            }
        } catch (Error err) {
            warning ("Unable to read indicators: %s", err.message);
        }
    }

    private void load_indicator (File parent_dir, bool legacy_lib, string name) {
        string indicator_path = parent_dir.get_child (name).get_path ();

        try {
            Indicator.Object indicator = null;

            if (legacy_lib) {
                if (!name.has_suffix (".so"))
                    return;

                debug ("Loading Indicator Library: %s", name);
                indicator = new Indicator.Object.from_file (indicator_path);
            } else {
                debug ("Loading Indicator File: %s", name);
                // indicator = new Indicator.Ng.for_profile (indicator_path, "desktop");
            }

            if (indicator != null)
                indicators.add (new IndicatorObject (indicator, name));
            else
                critical ("Unable to load %s: invalid object.", name);
        } catch (Error err) {
            warning ("Could not load indicator at %s: %s", indicator_path, err.message);
        }
    }
}
