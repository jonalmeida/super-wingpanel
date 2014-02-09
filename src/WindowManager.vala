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

using SuperWingpanel;
using SuperWingpanel.Widgets;
using SuperWingpanel.Drawing;

namespace SuperWingpanel {
    
    public class WindowManager : GLib.Object {

        private PanelController controller;

        // The Gtk.Window
        public WindowIface window;
        public PanelShadow shadow;

        public PositionManager position_manager;
        public PanelRenderer renderer;
        public HideManager hide_manager;

        public WingpanelApp app;

        public int monitor_number { 
            get {
                return controller.monitor_number;
            }
        }

        // Read settings from dconf
        public Services.Settings settings { 
            get {
                return controller.settings;
            }
        }

        public bool visible {
            get {
                return window.visible;
            }
            set {
                window.visible = value;
            }
        }

        public WindowManager (PanelController controller, WindowIface window_instance)
        {
            this.controller = controller;

            window = window_instance;
            window.set_window_manager (this);

            shadow = new PanelShadow ();

            position_manager = new PositionManager (this);
            renderer = new PanelRenderer (this);      
            hide_manager = new HideManager (this);

            hide_manager.initialize ();
            position_manager.initialize ();
            renderer.initialize ();
            
            window.show_all ();
            shadow.show_all ();
        }

        public void load_indicators (IndicatorLoader indicator_loader){
            window.load_indicators (indicator_loader);
        }
    }
}