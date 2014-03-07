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

using Gdk;

namespace SuperWingpanel.Widgets
{
    // reference needed for unmaximize call
    [DBus (name = "org.pantheon.gala")]
    interface Gala : Object {
        public abstract void perform_action (int type) throws IOError;
    }

    public class PrimaryWindow : WindowIface
    {
        private Gtk.Box left_wrapper;
        private Gtk.Box right_wrapper;
        private Gtk.SizeGroup size_group;
        private bool clock_is_centered = false;

        private IndicatorMenubar indicator_menubar;
        private MenuBar clock_menubar;
        private MenuBar apps_menubar;
        private IndicatorMenubar globalmenu_menubar;

        private Gtk.EventBox unmaximize_event;
        private Gtk.EventBox minimize_event;
        private Gtk.EventBox close_event;
        private Gtk.Label window_name;

        private bool indicator_globalmenu_loaded = false;

        public PrimaryWindow (WingpanelApp app)
        {
            base (app);

            left_wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            right_wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            container.set_homogeneous (false);
            left_wrapper.set_homogeneous (false);
            right_wrapper.set_homogeneous (false);

            add (container);

            var style_context = get_style_context ();
            style_context.add_class (StyleClass.PANEL);
            style_context.add_class (Gtk.STYLE_CLASS_MENUBAR);

            // Watch for mouse
            add_events (EventMask.ENTER_NOTIFY_MASK |
                        EventMask.LEAVE_NOTIFY_MASK |
                        EventMask.POINTER_MOTION_MASK);

            destroy.connect (Gtk.main_quit);
        }


        public override void set_window_manager(WindowManager window_manager)
        {
            manager = window_manager;
            add_window_buttons ();
            add_default_widgets (manager.settings);
        }

        public override Gtk.StyleContext get_draw_style_context ()
        {
            return indicator_menubar.get_style_context ();
        }

        private void add_default_widgets (Services.Settings settings)
        {
            // Apps button
            apps_menubar = new MenuBar ();
            var apps_button = new Widgets.AppsButton (settings);
            apps_menubar.append (apps_button);

            left_wrapper.pack_start (apps_menubar, false, true, 0);


            // Window Name
            window_name = new Gtk.Label(" ");
            window_name.get_style_context ().add_class (StyleClass.COMPOSITED_INDICATOR);
            left_wrapper.pack_start (window_name, false, true, 0);

            // Global Menu (holder)
            globalmenu_menubar = new IndicatorMenubar ();
            left_wrapper.pack_start (globalmenu_menubar, false, true, 0);

            
            container.pack_start (left_wrapper);

            clock_menubar = new MenuBar ();
            container.pack_start (clock_menubar, false, false, 0);

            // Menubar for storing indicators
            indicator_menubar = new IndicatorMenubar ();

            right_wrapper.pack_end (indicator_menubar, false, false, 0);
            container.pack_end (right_wrapper);



            size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            set_clock_centered (!manager.settings.enable_slim_mode);
        }

        public void add_window_buttons () {
            
            var button_layout_settings = new SuperWingpanel.Services.WMSettings();
            var buttons = button_layout_settings.button_layout.split(":");
            var s = "left";
            foreach (unowned string button in buttons) {
                var _buttons = button.split(",");
                if (s == "right") {
                    for (unowned int i = _buttons.length; i > 0; i--) {
                        var b = _buttons[i-1];
                        show_botton_on_side(b, s);
                    }
                } else {
                    foreach (unowned string b in _buttons) {
                        show_botton_on_side(b, s);
                    }
                }
                s = "right";
            }
        }

        private void show_botton_on_side(string button, string side) {
            var screen = Wnck.Screen.get_default ();
            switch (button) {
            case "close":
                var close_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                var close_icon = new Gtk.Image.from_file ("/usr/share/themes/elementary/metacity-1/close.svg");
                close_event = new Gtk.EventBox ();
                
                close_box.pack_start (close_icon, false, false, 2);
                close_event.add (close_box);
                
                close_event.set_visible_window (false);
                
                close_event.button_press_event.connect (() => {
                    screen.force_update();
                    var active_window = screen.get_active_window();
                    
                    if (active_window.get_window_type() == Wnck.WindowType.NORMAL) {
                        active_window.close(Gtk.get_current_event_time());
                    }
                    
                    return true;
                });
                if (side == "left") 
                    left_wrapper.pack_start (close_event, false, true, 0); 
                else 
                    right_wrapper.pack_end(close_event, false, true, 0);
                
                break;
                
            case "minimize":
                var minimize_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                var minimize_icon = new Gtk.Image.from_file ("/usr/share/themes/elementary/metacity-1/minimize.svg");
                minimize_event = new Gtk.EventBox ();
                
                minimize_box.pack_start (minimize_icon, false, false, 4);
                 
                minimize_event.add (minimize_box);
                minimize_event.set_visible_window (false);
                
                minimize_event.button_press_event.connect (() => {
                   screen.force_update();

                   try {
                        Gala gala = Bus.get_proxy_sync (BusType.SESSION, "org.pantheon.gala", "/org/pantheon/gala");
                        gala.perform_action (3); // action 2 = maximize/unmaximize
                    }
                    catch (IOError e)
                    {
                        // TODO: something...
                    }

                    return true;
                });
                if (side == "left") 
                    left_wrapper.pack_start (minimize_event, false, true, 0);
                else 
                    right_wrapper.pack_end(minimize_event, false, true, 0);
                
                break;       
            case "maximize":
                var unmaximize_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                var unmaximize_icon = new Gtk.Image.from_file ("/usr/share/themes/elementary/metacity-1/unmaximize.svg");
                unmaximize_event = new Gtk.EventBox ();
                
                unmaximize_box.pack_start (unmaximize_icon, false, false, 4);
                 
                unmaximize_event.add (unmaximize_box);
                unmaximize_event.set_visible_window (false);
                
                unmaximize_event.button_press_event.connect (() => {
                   screen.force_update();

                   try {
                        Gala gala = Bus.get_proxy_sync (BusType.SESSION, "org.pantheon.gala", "/org/pantheon/gala");
                        gala.perform_action (2); // action 2 = maximize/unmaximize
                    }
                    catch (IOError e)
                    {
                        // TODO: something...
                    }

                    return true;
                });
                if (side == "left") 
                    left_wrapper.pack_start (unmaximize_event, false, true, 0);
                else 
                    right_wrapper.pack_end(unmaximize_event, false, true, 0);
                break;
            default:
                break;
            }
        }

        public void set_clock_centered (bool enable) {
            if (manager.settings.show_datetime_in_tray)
                enable = false;

            if (enable != clock_is_centered) {
                clock_is_centered = enable;
                    
                if (enable)
                {
                    size_group.add_widget (left_wrapper);
                    size_group.add_widget (right_wrapper);
                }
                else
                {
                    size_group.remove_widget (left_wrapper);
                    size_group.remove_widget (right_wrapper);
                }
            }
        }

        public void show_app_button (bool enable) {
            if (enable)
                apps_menubar.show ();
            else
                apps_menubar.hide ();
        }

        public void change_datetime_position() {
            var old_box = manager.settings.show_datetime_in_tray ? clock_menubar : indicator_menubar;
            
            foreach (weak Gtk.Widget widget in old_box.get_children()) {
                var entry = (IndicatorWidget)widget;
                if (entry.get_indicator().get_name() == "libdatetime.so") {
                    old_box.remove(widget);
                    load_indicator(entry.get_indicator());
                }
            }
        }

        public void show_window_controls (bool enable) {
            if (close_event != null) 
                close_event.set_visible (enable);
            if (minimize_event != null)
                minimize_event.set_visible (enable);
            if (unmaximize_event != null)
                unmaximize_event.set_visible (enable);
            if (window_name != null)
                window_name.set_visible (enable || indicator_globalmenu_loaded); // if global menu is loaded, always show the window name
        }


        public void set_window_text (string window_text) {
            if (window_text.length > 30)
                window_name.set_markup (window_text.up ().slice (0, 27) + "...");
            else
                window_name.set_markup (window_text.up ());
        }

        public override void load_indicators (IndicatorLoader indicator_loader) {
            var indicators = indicator_loader.get_indicators ();

            foreach (var indicator in indicators)
                load_indicator (indicator);
        }

        private void load_indicator (IndicatorIface indicator) {
            var entries = indicator.get_entries ();

            foreach (var entry in entries)
                create_entry (entry);

            indicator.entry_added.connect (create_entry);
            indicator.entry_removed.connect (delete_entry);
        } 

        private void create_entry (IndicatorWidget entry) {
            string entry_name = entry.get_indicator ().get_name ();

            if (entry_name == "libdatetime.so") {
                if (manager.settings.show_datetime_in_tray)
                    indicator_menubar.insert_sorted (entry);
                else
                    clock_menubar.prepend (entry);
            }
            else if (entry_name == "libappmenu.so") {
                globalmenu_menubar.push_back (entry);
                indicator_globalmenu_loaded = true;
                show_window_controls (manager.settings.show_window_controls);
            } else
                indicator_menubar.insert_sorted (entry);
        }

        private void delete_entry (IndicatorWidget entry) {
            if (entry.get_indicator ().get_name () == "libappmenu.so") {
                indicator_globalmenu_loaded = false;
                show_window_controls (manager.settings.show_window_controls);
            }
            entry.parent.remove (entry);
        }

        public override void update_size_and_position () {
            update_clock_alignment ();

            unowned PositionManager position_manager = manager.position_manager;
            position_manager.update_size_and_position ();

            move (position_manager.X, position_manager.Y);
            set_size_request (position_manager.W, position_manager.H);

            manager.shadow.update_size_and_position (position_manager.shadow_X, position_manager.shadow_Y, position_manager.shadow_W, position_manager.shadow_H);
        }


        public void update_clock_alignment () {
            if (manager.settings.enable_slim_mode)
                set_clock_centered (false);
            else if (manager.settings.hide_mode == HideType.INTELLISLIM && manager.renderer.hide_progress >= 0.5)
                set_clock_centered (false);
            else
                set_clock_centered  (true);
        }

        public override bool draw (Cairo.Context cr) {
            manager.renderer.draw_panel (cr);
            return true;
        }
    }

}