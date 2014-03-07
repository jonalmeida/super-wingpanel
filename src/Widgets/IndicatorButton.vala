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

        public new void set_label (Gtk.Label? label) {
            Gtk.Widget old_widget = the_label;

            if (old_widget != null) {
                if (old_widget.get_parent () is Gtk.Container) {
                    box.remove (old_widget);
                    old_widget.get_style_context ().remove_class (StyleClass.COMPOSITED_INDICATOR);
                }
            }

            if (label != null){
                label.get_style_context ().add_class (StyleClass.COMPOSITED_INDICATOR);

                the_label = label;
                box.pack_start (the_label, false, false, 0);
            }
        }

        public void set_image (Gtk.Image? image) {
            Gtk.Widget old_widget = the_image;

            if (old_widget != null) {
                if (old_widget.get_parent () is Gtk.Container) {
                    box.remove (old_widget);
                    old_widget.get_style_context ().remove_class (StyleClass.COMPOSITED_INDICATOR);
                }
            }

            if (image != null ) {
                image.get_style_context ().add_class (StyleClass.COMPOSITED_INDICATOR);

                the_image = image;
                box.pack_start (the_image, false, false, 0);                
            }
        }
    }
}