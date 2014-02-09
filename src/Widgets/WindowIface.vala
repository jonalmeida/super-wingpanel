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

using SuperWingpanel.Widgets;
namespace SuperWingpanel.Widgets {
    
    public abstract class WindowIface : Gtk.Window {

        // The WindowManager object that manages the window/position/hide-state/rendering
        protected WindowManager manager { get; set; }

        // The main container where all the stuff goes
        protected Gtk.Box container;

        public WindowIface (WingpanelApp app) {
            decorated = false;
            resizable = false;
            skip_taskbar_hint = true;
            app_paintable = true;
            set_visual (get_screen ().get_rgba_visual ());
            set_type_hint (Gdk.WindowTypeHint.DOCK);

            set_application (app as Gtk.Application);

            
            var style_context = get_style_context ();
            style_context.add_class (StyleClass.PANEL);
            style_context.add_class (Gtk.STYLE_CLASS_MENUBAR);

            container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            container.set_homogeneous (false);
            container.margin_left = SuperWingpanel.Drawing.PanelRenderer.SLIM_PANEL_EDGE_PADDING;
            container.margin_right = SuperWingpanel.Drawing.PanelRenderer.SLIM_PANEL_EDGE_PADDING;

            add (container);

        }

        public abstract void set_window_manager(WindowManager manager);
        public abstract void load_indicators (IndicatorLoader indicator_loader);
        public abstract void update_size_and_position ();
        public abstract Gtk.StyleContext get_draw_style_context ();
    }
}