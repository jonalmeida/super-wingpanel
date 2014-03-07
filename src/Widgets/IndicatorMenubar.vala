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

namespace SuperWingpanel.Widgets {
    public class IndicatorMenubar : MenuBar {
        private List<IndicatorWidget> sorted_items;
        private bool update_pending = false;
        public signal void finished_loading ();

        public IndicatorMenubar () {
            sorted_items = new List<IndicatorWidget> ();
        }

        public void insert_sorted (IndicatorWidget item) {
            if (sorted_items.index (item) >= 0)
                return; // item already added

            sorted_items.insert_sorted (item, (CompareFunc) Services.IndicatorSorter.compare_func);

            apply_new_order.begin ();
        }

        public void push_back (IndicatorWidget item) {
            if (sorted_items.index (item) >= 0)
                return; // item already added

            sorted_items.append (item);

            apply_new_order.begin ();
        }
        
        public override void remove (Gtk.Widget widget) {
            var indicator_widget = widget as IndicatorWidget;
            if (indicator_widget != null)
                sorted_items.remove (indicator_widget);

            base.remove (widget);
        }

        private async void apply_new_order () {
            if (update_pending)
                return;

            update_pending = true;

            Idle.add (apply_new_order.callback);
            yield;

            clear ();
            append_all_items ();

            update_pending = false;
        }

        private void clear () {
            var children = get_children ();

            foreach (var child in children)
                base.remove (child);
        }

        private void append_all_items () {
            foreach (var widget in sorted_items)
                append (widget);
            finished_loading ();
        }
    }
}