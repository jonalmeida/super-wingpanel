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
    public class IndicatorButton : Gtk.MenuItem {
        public enum WidgetSlot {
            LABEL,
            IMAGE
        }

        private Gtk.Widget the_label;
        private Gtk.Widget the_image;
        private Gtk.Box box;

        public IndicatorButton () {
            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.set_homogeneous (false);
            box.spacing = 2;

            add (box);
            box.show ();

            get_style_context ().add_class (StyleClass.COMPOSITED_INDICATOR);

            // Enable scrolling events
            add_events (Gdk.EventMask.SCROLL_MASK);
        }

        public void set_widget (WidgetSlot slot, Gtk.Widget widget) {

            if (the_label != null) {
                box.remove (the_label);
                the_label.get_style_context ().remove_class (StyleClass.COMPOSITED_INDICATOR);
            }

            if (the_image != null) {
                box.remove (the_image);
                the_image.get_style_context ().remove_class (StyleClass.COMPOSITED_INDICATOR);
            }

            if (widget.get_parent() != null) widget.unparent();
            widget.get_style_context ().add_class (StyleClass.COMPOSITED_INDICATOR);

            if (slot == WidgetSlot.LABEL) {
                the_label = widget;
                box.pack_end (the_label, false, false, 0);
            } else if (slot == WidgetSlot.IMAGE) {
                the_image = widget;
                box.pack_start (the_image, false, false, 0);
            } else {
                assert_not_reached ();
            }
        }
    }
}