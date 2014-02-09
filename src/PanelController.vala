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

using Gtk;
using SuperWingpanel;
using SuperWingpanel.Widgets;
using SuperWingpanel.Drawing;
using Wnck;
using Gdk;

namespace SuperWingpanel {
    
public class PanelController : GLib.Object  {

        public WingpanelApp app;

        WindowManager primary_window;
        WindowManager apps_button_window;

        private Backend.IndicatorFactory indicator_loader;

        // Read settings from dconf
        public Services.Settings settings;
        
        
        private int _monitor_number;
        public int monitor_number {
            get{
                 if (_monitor_number < 0 || _monitor_number > Gdk.Screen.get_default ().get_n_monitors () - 1){
                    debug ("monitor_number: %d", Gdk.Screen.get_default ().get_primary_monitor ());
                    return Gdk.Screen.get_default ().get_primary_monitor ();
                 }
                else
                {
                    debug ("monitor_number: %d", _monitor_number);
                    return _monitor_number;
                }
                    
            }
            private set {
                _monitor_number = value;
            }
        }
        
        


        public PanelController (WingpanelApp app, int monitor_no)
        {
            this.app = app;
            monitor_number = monitor_no;
            settings = new Services.Settings ();

            // Create the windows
            primary_window = new WindowManager (this, new PrimaryWindow (app));
            apps_button_window = new WindowManager (this, new AppButtonWindow (app));
            apps_button_window.position_manager.override_X = 32;
            apps_button_window.position_manager.override_W = -1;

            // Load the indicators
            Services.IndicatorSorter.set_order(settings.indicator_order);

            indicator_loader = new Backend.IndicatorFactory (settings);
            primary_window.load_indicators (indicator_loader);

            // Listen for settings changes
            settings.notify["hide-mode"].connect (hide_mode_changed);
            settings.notify["slim-panel-separate-launcher"].connect (separate_launcher_changed);
            settings.notify["show-launcher"].connect (separate_launcher_changed);
            settings.notify["enable-slim-mode"].connect (enable_slim_mode_changed);
            settings.notify["slim-panel-margin"].connect (margin_changed);
            settings.notify["show-window-controls"].connect (window_controls_changed);
            settings.notify["show-datetime-in-tray"].connect (datetime_position_changed);
            
            
            // start listening for active window changes
            var screen = Wnck.Screen.get (monitor_number);
            screen.active_window_changed.connect (active_window_changed);
            active_window_changed (null);

            // start listening for name changes on the current active window
            var active_window = screen.get_active_window ();
            active_window.name_changed.connect (process_window_name_change);
            process_window_name_change ();

            separate_launcher_changed ();
            window_controls_changed ();
            decorate_all_windows ();
            set_struts ();
        }

        private void datetime_position_changed () {
            ((PrimaryWindow) primary_window.window).change_datetime_position();
        }

        private void hide_mode_changed () {
            separate_launcher_changed ();
            window_controls_changed ();
            set_struts ();
        }

        private void separate_launcher_changed () {
            if (settings.show_launcher && settings.slim_panel_separate_launcher && settings.enable_slim_mode) {
                apps_button_window.window.visible = true;
                apps_button_window.shadow.visible = true;
                apps_button_window.window.update_size_and_position ();
                ((PrimaryWindow)primary_window.window).show_app_button (false);
            } else {
                apps_button_window.window.visible = false;
                apps_button_window.shadow.visible = false;
                ((PrimaryWindow)primary_window.window).show_app_button (true);
            }
        }

        private void enable_slim_mode_changed () {
            primary_window.window.update_size_and_position ();
            separate_launcher_changed ();
            set_struts ();
        }

        private void margin_changed () {
            primary_window.window.update_size_and_position ();
            apps_button_window.window.update_size_and_position ();
        }

        private void window_controls_changed () {
            var screen = Wnck.Screen.get (monitor_number);

            if (settings.show_window_controls && settings.hide_mode != HideType.INTELLISLIM && !settings.enable_slim_mode) {
                active_window_changed (null);
            } else {
                // hide the controls
                ((PrimaryWindow) primary_window.window).show_window_controls (false);
            }
            decorate_all_windows ();

        }


        private void decorate_all_windows () {
            foreach (unowned Gdk.Window window in Gdk.Display.get_default ().get_screen (monitor_number).get_window_stack()) {
                if (settings.show_window_controls & window.get_state() == Gdk.WindowState.MAXIMIZED) {
                    window.set_decorations(Gdk.WMDecoration.BORDER);
                }else {
                    window.set_decorations(Gdk.WMDecoration.ALL);
                }
            }
        }

        private void active_window_changed (Wnck.Window? previous_window) {
            var screen = Wnck.Screen.get (monitor_number);

            // Stop listening for state changes from the old window
            if (previous_window != null) {
                previous_window.state_changed.disconnect (process_window_state_change);
                previous_window.name_changed.disconnect (process_window_name_change);
            }

            // start listening for state changes from the active window
            var active_window = screen.get_active_window();
            active_window.state_changed.connect (process_window_state_change);
            active_window.name_changed.connect (process_window_name_change);

            // Update with the state of the active window
            process_window_state_change (active_window.get_state (), active_window.get_state ());
            process_window_name_change ();

        }

        public void process_window_state_change (Wnck.WindowState changed_mask, Wnck.WindowState new_state)
        {
            var window = ((PrimaryWindow) primary_window.window);

            if (settings.show_window_controls 
                && settings.hide_mode != HideType.INTELLISLIM 
                && !settings.enable_slim_mode
                && new_state == (Wnck.WindowState.MAXIMIZED_HORIZONTALLY | Wnck.WindowState.MAXIMIZED_VERTICALLY))
            {
                    window.show_window_controls (true);
                    decorate_active_window (false);
            }
            else
            {
                decorate_active_window (true);
                window.show_window_controls (false);
            }
        }

        public void process_window_name_change () {
            var screen = Wnck.Screen.get (monitor_number);
            var active_window = screen.get_active_window();
            var window_text = "";

            if (active_window.has_name () && active_window.get_window_type () == Wnck.WindowType.NORMAL) {
                window_text = active_window.get_application().get_name (); 
            } else if (screen.get_showing_desktop ()) {
                window_text = "Desktop";
            } else {
                window_text = " ";
            }

            ((PrimaryWindow) primary_window.window).set_window_text (window_text);
        }


        private void decorate_active_window (bool decorate) {
            if (settings.show_window_controls){
                var active_window = Gdk.Display.get_default ().get_screen (monitor_number).get_active_window ();
                if (decorate || settings.enable_slim_mode) {
                    active_window.set_decorations (Gdk.WMDecoration.ALL);
                } else {
                    active_window.set_decorations (Gdk.WMDecoration.BORDER);
                }
            }
        }


        private enum Struts {
            LEFT,
            RIGHT,
            TOP,
            BOTTOM,
            LEFT_START,
            LEFT_END,
            RIGHT_START,
            RIGHT_END,
            TOP_START,
            TOP_END,
            BOTTOM_START,
            BOTTOM_END,
            N_VALUES
        }

        public void set_struts () 
        {
            unowned PositionManager position_manager = primary_window.position_manager;

            if (!primary_window.window.get_realized ())
                return;

            int x, y, w, h;

            if (settings.hide_mode == HideType.NEVER_HIDE)
            {
                x = position_manager.X;
                y = position_manager.Y;

                w = position_manager.W;
                h = position_manager.H;
            }
            else
            {
                x = position_manager.monitor_geo.x;
                y = position_manager.monitor_geo.y;

                w = position_manager.monitor_geo.width;
                h = 0;
            }
                // Since uchar is 8 bits in vala but the struts are 32 bits
                // we have to allocate 4 times as much and do bit-masking
                var struts = new ulong[Struts.N_VALUES];

                struts[Struts.TOP] = h + y;
                struts[Struts.TOP_START] = x;
                struts[Struts.TOP_END] = x + w;

                var first_struts = new ulong[Struts.BOTTOM + 1];
                for (var i = 0; i < first_struts.length; i++)
                    first_struts[i] = struts[i];

                unowned X.Display display = Gdk.X11Display.get_xdisplay (primary_window.window.get_display ());
                var xid = Gdk.X11Window.get_xid (primary_window.window.get_window ());

                display.change_property (xid, display.intern_atom ("_NET_WM_STRUT_PARTIAL", false), X.XA_CARDINAL,
                                         32, X.PropMode.Replace, (uchar[]) struts, struts.length);
                display.change_property (xid, display.intern_atom ("_NET_WM_STRUT", false), X.XA_CARDINAL,
                                         32, X.PropMode.Replace, (uchar[]) first_struts, first_struts.length);
            

        }
    }
}