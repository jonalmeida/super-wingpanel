// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2012 Wingpanel Developers
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

    public class AppButtonWindow : WindowIface 
    {
        private AppsButton apps_button;
        private MenuBar menubar;

        public AppButtonWindow (WingpanelApp app) 
        {
            base (app);
        }

        public override void set_window_manager(WindowManager window_manager)
        {
            manager = window_manager;
            add_default_widgets ();
        }

        public override void load_indicators (IndicatorLoader indicator_loader) { }

        public override Gtk.StyleContext get_draw_style_context () {
            return menubar.get_style_context ();
        }

        private void add_default_widgets () {
            apps_button = new Widgets.AppsButton (manager.settings);

            menubar = new MenuBar ();            
            menubar.append (apps_button);
            container.pack_start (menubar);
        }
        
        public override void update_size_and_position ()
        {
            unowned PositionManager position_manager = manager.position_manager;
            position_manager.update_size_and_position ();

            // This window will always be at the top left and will always be as slim as possible
            move (position_manager.X, position_manager.Y);
            set_size_request (position_manager.W, position_manager.H);

            manager.shadow.update_size_and_position (position_manager.shadow_X, position_manager.shadow_Y, position_manager.shadow_W, position_manager.shadow_H);
        }


        public override bool draw (Cairo.Context cr) {
            manager.renderer.draw_panel (cr);
            return true;
        }
    }
}
