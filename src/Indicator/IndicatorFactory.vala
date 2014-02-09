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
    private IndicatorFileModel model;
    private Gee.Collection<IndicatorIface> indicators;
    private bool initted = false;

    public IndicatorFactory (Services.Settings settings) {
        model = new IndicatorFileModel (settings);
    }

    public Gee.Collection<IndicatorIface> get_indicators () {
        if (!initted) {
            load_indicators ();
            initted = true;
        }

        return indicators.read_only_view;
    }

    private void load_indicators () {
        indicators = new Gee.LinkedList<IndicatorIface> ();
        var indicators_list = model.get_indicators ();

        foreach (var indicator in indicators_list) {
            string name = model.get_indicator_name (indicator);
            indicators.add (new IndicatorObject (indicator, name));
        }

    }
}
