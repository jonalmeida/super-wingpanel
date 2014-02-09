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
using Wnck;
using SuperWingpanel.Services;
using SuperWingpanel.Widgets;

namespace SuperWingpanel
{
    public enum HideType
    {
        NEVER_HIDE,
        INTELLIHIDE,
        INTELLISLIM,
        AUTO_HIDE
    }

    public class HideManager : GLib.Object
    {
        // a delay between window changes and updating our data
        // this allows window animations to occur, which might change
        // the results of our update
        const uint UPDATE_TIMEOUT = 200;

        public WindowManager manager { private get; construct; }

        public bool Hidden { get; private set; default = true; }

        public bool Disabled { get; private set; default = false; }

        public bool PanelHovered { get; private set; default = false; }

        uint timer_unhide = 0;
        bool pointer_update = true;


        public HideManager (WindowManager manager)
        {
            GLib.Object (manager : manager);
        }
        
        construct
        {
            windows_intersect = false;
            
            notify["Disabled"].connect (update_hidden);
            notify["PanelHovered"].connect (update_hidden);
            manager.settings.notify["hide-mode"].connect (settings_changed);
        }

        public void initialize ()
            requires (manager.window != null)
        {
            manager.window.enter_notify_event.connect (enter_notify_event);
            manager.window.leave_notify_event.connect (leave_notify_event);
            manager.window.motion_notify_event.connect (motion_notify_event);
            
            // manager.drag_manager.notify["ExternalDragActive"].connect (update_panel_hovered);
            // manager.drag_manager.notify["InternalDragActive"].connect (update_panel_hovered);
            
            Wnck.Screen.get_default ().active_window_changed.connect (handle_window_changed);
            Wnck.Screen.get_default ().active_workspace_changed.connect (handle_workspace_changed);
            
            setup_active_window ();
        }


        ~HideManager ()
        {
            notify["Disabled"].disconnect (update_hidden);
            notify["PanelHovered"].disconnect (update_hidden);
            manager.settings.notify["hide_mode"].disconnect (settings_changed);
            
            manager.window.enter_notify_event.disconnect (enter_notify_event);
            manager.window.leave_notify_event.disconnect (leave_notify_event);
            manager.window.motion_notify_event.disconnect (motion_notify_event);
            
            // manager.drag_manager.notify["ExternalDragActive"].disconnect (update_panel_hovered);
            // manager.drag_manager.notify["InternalDragActive"].disconnect (update_panel_hovered);
             
            Wnck.Screen.get_default ().active_window_changed.disconnect (handle_window_changed);
            Wnck.Screen.get_default ().active_workspace_changed.disconnect (handle_workspace_changed);
            
            stop_timers ();
        }

        /**
         * Checks to see if the panel is being hovered by the mouse cursor.
         */
        public void update_panel_hovered ()
        {
            unowned PositionManager position_manager = manager.position_manager;
            unowned WindowIface window = manager.window;
            //unowned DragManager drag_manager = manager.drag_manager;
            
            // get current mouse pointer location
            int x, y;
            window.get_display ().get_device_manager ().get_client_pointer ().get_position (null, out x, out y);
            
            // compute rect of the window
            var panel_rect = position_manager.get_cursor_region ();
            
            // use the panel rect and cursor location to determine if panel is hovered
            var hovered = (x >= panel_rect.x && x < panel_rect.x + panel_rect.width
                && y >= panel_rect.y && y < panel_rect.y + panel_rect.height);
            
            if (PanelHovered != hovered)
                PanelHovered = hovered;
            
            // disable hiding if drags are active
            // var disabled = (drag_manager.InternalDragActive || drag_manager.ExternalDragActive);
            // if (Disabled != disabled)
            //     Disabled = disabled;

        }

        void settings_changed ()
        {
            manager.window.update_size_and_position ();
            update_panel_hovered ();
            update_window_intersect ();
            manager.window.queue_draw ();
        }

        void update_hidden ()
        {
            if (Disabled) {
                if (Hidden)
                    Hidden = false;
                return;
            }

            switch (manager.settings.hide_mode) {
            default:
            case HideType.NEVER_HIDE:
                show ();

                // TODO Make panel opaque/transparent when an app is maximized
                //if (active_maximized_window_intersect)
                //else
                
                break;
            
            case HideType.INTELLIHIDE:
                if (PanelHovered || !windows_intersect)
                    show ();
                else
                    hide ();
                break;
            
            case HideType.AUTO_HIDE:
                if (PanelHovered)
                    show ();
                else
                    hide ();
                break;
            
            case HideType.INTELLISLIM:
                if (!(windows_intersect || active_maximized_window_intersect || dialog_windows_intersect))
                    show ();
                else
                    hide ();
                break;
            }
            pointer_update = true;
        }

        void hide ()
        {
            if (timer_unhide > 0) {
                GLib.Source.remove (timer_unhide);
                timer_unhide = 0;
            }
            
            if (!Hidden)
                Hidden = true;
        }

        void show ()
        {
            if (!pointer_update || manager.settings.UnhideDelay == 0) {
                if (Hidden)
                    Hidden = false;
                return;
            }
            
            if (timer_unhide > 0)
                return;
            
            timer_unhide = Gdk.threads_add_timeout (manager.settings.UnhideDelay, () => {
                if (Hidden)
                    Hidden = false;
                timer_unhide = 0;
                return false;
            });
        }

        bool enter_notify_event (EventCrossing event)
        {
            if (event.detail == NotifyType.INFERIOR)
                return Hidden;

            if ((bool) event.send_event)
                PanelHovered = true;
            else
                update_panel_hovered ();
            
            return Hidden;
        }

        bool leave_notify_event (EventCrossing event)
        {
            if (event.detail == NotifyType.INFERIOR)
                return false;
            
            // ignore this event if it was sent explicitly
            if ((bool) event.send_event)
                return false;
            
            if (PanelHovered) // && !manager.window.menu_is_visible ()
                update_panel_hovered ();
            
            return false;
        }
        
        bool motion_notify_event (EventMotion event)
        {
            update_panel_hovered ();
            
            return Hidden;
        }




        //
        // intelligent hiding code
        //
        
        bool windows_intersect;
        bool active_maximized_window_intersect;
        bool dialog_windows_intersect;
        Gdk.Rectangle last_window_rect;
        
        uint timer_geo;
        uint timer_window_changed;
        
        void update_window_intersect ()
        {
            var panel_rect = manager.position_manager.get_static_panel_region ();
            
            var intersect = false;
            var dialog_intersect = false;
            var active_maximized_intersect = false;
            var screen = Wnck.Screen.get_default ();
            var active_window = screen.get_active_window ();
            var active_workspace = screen.get_active_workspace ();
            
            if (active_window != null && active_workspace != null)
                foreach (var w in screen.get_windows ()) {
                    if (w.is_minimized ())
                        continue;
                    var type = w.get_window_type ();
                    if (type == Wnck.WindowType.DESKTOP || type == Wnck.WindowType.DOCK
                        || type == Wnck.WindowType.MENU || type == Wnck.WindowType.SPLASHSCREEN)
                        continue;
                    if (!w.is_visible_on_workspace (active_workspace))
                        continue;
                    if (w.get_pid () != active_window.get_pid ())
                        continue;
                    
                    if (window_geometry (w).intersect (panel_rect, null)) {
                        intersect = true;
                        
                        active_maximized_intersect = active_maximized_intersect || (active_window == w
                            && (w.is_maximized () || w.is_maximized_vertically () || w.is_maximized_horizontally ()));
                        
                        dialog_intersect = dialog_intersect || type == Wnck.WindowType.DIALOG;
                        
                        if (active_maximized_intersect && dialog_intersect)
                            break;
                    }
                }
            
            windows_intersect = intersect;
            dialog_windows_intersect = dialog_intersect;
            active_maximized_window_intersect = active_maximized_intersect;
            
            pointer_update = false;
            update_hidden ();
        }

        void schedule_update ()
        {
            if (timer_window_changed > 0)
                return;
            
            timer_window_changed = Gdk.threads_add_timeout (UPDATE_TIMEOUT, () => {
                update_window_intersect ();
                timer_window_changed = 0;
                return false;
            });
        }

        void handle_workspace_changed (Wnck.Workspace? previous)
        {
            schedule_update ();
        }

        void handle_window_changed (Wnck.Window? previous)
        {
            if (previous != null) {
                previous.geometry_changed.disconnect (handle_geometry_changed);
                previous.state_changed.disconnect (handle_state_changed);
            }
            
            setup_active_window ();
        }
        
        void setup_active_window ()
        {
            var active_window = Wnck.Screen.get_default ().get_active_window ();
            
            if (active_window != null) {
                last_window_rect = window_geometry (active_window);
                active_window.geometry_changed.connect (handle_geometry_changed);
                active_window.state_changed.connect (handle_state_changed);
            }
            
            schedule_update ();
        }

        void handle_state_changed (Wnck.WindowState changed_mask, Wnck.WindowState new_state)
        {
            if ((changed_mask & Wnck.WindowState.MINIMIZED) == 0)
                return;
            
            schedule_update ();
        }
        
        void handle_geometry_changed (Wnck.Window? w)
        {
            return_if_fail (w != null);
            
            var geo = window_geometry (w);
            if (geo == last_window_rect)
                return;
            
            last_window_rect = geo;
            
            if (timer_geo > 0)
                return;
            
            timer_geo = Gdk.threads_add_timeout (UPDATE_TIMEOUT, () => {
                update_window_intersect ();
                timer_geo = 0;
                return false;
            });
        }
        
        Gdk.Rectangle window_geometry (Wnck.Window w)
        {
            var win_rect = Gdk.Rectangle ();
            w.get_geometry (out win_rect.x, out win_rect.y, out win_rect.width, out win_rect.height);
            return win_rect;
        }
        
        void stop_timers ()
        {
            if (timer_geo > 0) {
                GLib.Source.remove (timer_geo);
                timer_geo = 0;
            }
            
            if (timer_window_changed > 0) {
                GLib.Source.remove (timer_window_changed);
                timer_window_changed = 0;
            }
            
            if (timer_unhide > 0) {
                GLib.Source.remove (timer_unhide);
                timer_unhide = 0;
            }
        }
    }

}