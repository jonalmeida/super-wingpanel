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

public class SuperWingpanel.Backend.IndicatorObject : Object, IndicatorIface {
    private Indicator.Object object;
    private Gee.HashMap<unowned Indicator.ObjectEntry, IndicatorWidget> entries;
    private string name;

    public IndicatorObject (Indicator.Object object, string name) {
        this.object = object;
        this.name = name;

        entries = new Gee.HashMap<unowned Indicator.ObjectEntry, IndicatorWidget> ();

        load_entries ();

        object.entry_added.connect (on_entry_added);
        object.entry_removed.connect (on_entry_removed);
    }

    ~IndicatorObject () {
        object.entry_added.disconnect (on_entry_added);
        object.entry_removed.disconnect (on_entry_removed);
    }

    public string get_name () {
        return name;
    }

    public Gee.Collection<IndicatorWidget> get_entries () {
        return entries.values;
    }

    private void load_entries () {
        List<unowned Indicator.ObjectEntry> list = object.get_entries ();

        foreach (var entry in list)
            entries.set (entry, create_entry (entry));
    }

    private void on_entry_added (Indicator.Object object, Indicator.ObjectEntry entry) {
        assert (this.object == object);

        var entry_widget = create_entry (entry);
        entries.set (entry, entry_widget);

        entry_added (entry_widget);
    }

    private void on_entry_removed (Indicator.Object object, Indicator.ObjectEntry entry) {
        assert (this.object == object);
 
        var entry_widget = entries.get (entry);
        entries.unset (entry);
 
        entry_removed (entry_widget);
    }

    private IndicatorWidget create_entry (Indicator.ObjectEntry entry) {
        return new IndicatorObjectEntry (entry, this);
    }
}
