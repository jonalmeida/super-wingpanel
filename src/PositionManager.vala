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

namespace SuperWingpanel {

    public enum PanelPosition {
        LEFT = 0,
        MIDDLE = 1,
        RIGHT = 2,
        FLUSH_LEFT = 3,
        FLUSH_RIGHT = 4
    }

    /**
     * Handles positioning the wingpanel
     */
    public class PositionManager : GLib.Object
    {
        public WindowManager manager { private get; construct; }
        public Gdk.Rectangle monitor_geo { get; private set; }
        Gdk.Rectangle static_panel_region; // This is the area the panel occupies when not hidden


        public int X { get; private set; }
        public int Y { get; private set; }
        public int W { get; private set; }
        public int H { get; private set; }

        public int shadow_X { get; private set; }
        public int shadow_Y { get; private set; }
        public int shadow_W { get; private set; }
        public int shadow_H { get; private set; }


        public int override_X { get; set; default = -1; }
        public int override_W { get; set; default = -1; }

        const int DEFAULT_HEIGHT = 26;
        const int DEFAULT_SHADOW_HEIGHT = 4;


        public PositionManager (WindowManager manager)
        {
            GLib.Object (manager : manager);
            static_panel_region = Gdk.Rectangle ();
        }

        public void initialize ()
            requires(manager.window != null)
        {
            unowned Screen screen = manager.window.get_screen ();

            screen.monitors_changed.connect (update_monitor_geo);
            screen.size_changed.connect (update_monitor_geo);
            manager.settings.notify["slim_panel_position"].connect (position_changed);

            update_monitor_geo ();
            position_changed ();
        }

        ~PositionManager ()
        {
            unowned Screen screen = manager.window.get_screen ();
            
            screen.monitors_changed.disconnect (update_monitor_geo);
            screen.size_changed.disconnect (update_monitor_geo);
            manager.settings.notify["slim_panel_position"].disconnect (position_changed);
        }



        void update_monitor_geo ()
        {
            unowned Screen screen = manager.window.get_screen ();
            Gdk.Rectangle monitor_rect;
            screen.get_monitor_geometry (manager.monitor_number, out monitor_rect);
            monitor_geo = monitor_rect;
            manager.window.update_size_and_position ();
        }

        void position_changed ()
        {            
            manager.window.update_size_and_position ();
        }

        public void update_size_and_position () {

            // if we have multiple monitors, we must check if the panel would be placed inbetween
            // monitors. If that's the case we have to move it to the topmost, or we'll make the 
            // upper monitor unusable because of the struts.
            // First check if there are monitors overlapping horizontally and if they are higher 
            // our current highest, make this one the new highest and test all again
            unowned Screen screen = manager.window.get_screen ();
            if (screen.get_n_monitors () > 1) {
                Gdk.Rectangle dimensions;
                for (var i = 0; i < screen.get_n_monitors (); i++) {
                    screen.get_monitor_geometry (i, out dimensions);
                    if (((dimensions.x >= monitor_geo.x
                        && dimensions.x < monitor_geo.x + monitor_geo.width)
                        || (dimensions.x + dimensions.width > monitor_geo.x
                        && dimensions.x + dimensions.width <= monitor_geo.x + monitor_geo.width)
                        || (dimensions.x < monitor_geo.x
                        && dimensions.x + dimensions.width > monitor_geo.x + monitor_geo.width))
                        && dimensions.y < monitor_geo.y) {
                        warning ("Not placing wingpanel on the primary monitor because of problems" +
                            " with multimonitor setups");
                        monitor_geo = dimensions;
                        i = 0;
                    }
                }
            }


            if (manager.settings.enable_slim_mode)
            {
                X = get_slim_x_coord ();
                Y = monitor_geo.y;
                W = -1;
                H = DEFAULT_HEIGHT;
            }
            else 
            {
                X = monitor_geo.x;
                Y = monitor_geo.y;
                W = monitor_geo.width;
                H = DEFAULT_HEIGHT;
            }

            if (override_X >= 0)
                X = override_X;
            if (override_W >= 0)
                W = override_W;

            var progress = manager.renderer.hide_progress;
            if (progress > 0)
            {
                if (manager.settings.hide_mode == HideType.INTELLISLIM && !manager.settings.enable_slim_mode)
                {
                    if (progress >= 0.5)
                    {
                        W = -1;
                        X = get_slim_x_coord ();
                    }
                }
                else 
                {   
                    Y -= int.max(1, (int) (progress * DEFAULT_HEIGHT)) - 1;
                }
            }


            shadow_X = X;
            shadow_Y = Y + H;
            if ((manager.settings.hide_mode == HideType.INTELLISLIM && progress > 0.5) || manager.settings.enable_slim_mode) {
                Gtk.Allocation size;
                manager.window.get_allocation (out size);
                shadow_X += Drawing.PanelRenderer.SLIM_PANEL_EDGE_PADDING;
                shadow_W = size.width - 2 * Drawing.PanelRenderer.SLIM_PANEL_EDGE_PADDING;
            } else {
                shadow_W = W;
            }
            shadow_H = DEFAULT_SHADOW_HEIGHT;
        }

        private int get_slim_x_coord ()
        {
            Gtk.Allocation size;
            manager.window.get_allocation (out size);

            var panel_position = manager.settings.slim_panel_position;
            var margin = manager.settings.slim_panel_margin;

            if (panel_position == PanelPosition.RIGHT)
                return monitor_geo.x + monitor_geo.width - size.width - margin;
            else if (panel_position == PanelPosition.MIDDLE)
                return monitor_geo.x + (monitor_geo.width / 2) - (size.width / 2);
            else if (panel_position == PanelPosition.LEFT)
                return monitor_geo.x + margin;
            else if (panel_position == PanelPosition.FLUSH_RIGHT)
                return monitor_geo.x + monitor_geo.width - size.width;
            else if (panel_position == PanelPosition.FLUSH_LEFT)
                return monitor_geo.x;
            else
                return 0;
        }


        /**
         * Returns the static panel region for the panel.
         * This is the region that the panel occupies when not hidden.
         *
         * @return the static panel region for the panel
         */
        public Gdk.Rectangle get_static_panel_region ()
        {
            
            var panel_region = Gdk.Rectangle ();
            panel_region.x = monitor_geo.x;
            panel_region.y = monitor_geo.y;
            panel_region.width = monitor_geo.width;
            panel_region.height = DEFAULT_HEIGHT;
            
            return panel_region;
        }

        /**
         * Returns the cursor region for the panel.
         * This is the region that the cursor can interact with the panel.
         *
         * @return the cursor region for the panel
         */
        public Gdk.Rectangle get_cursor_region ()
        {
            var cursor_region = Gdk.Rectangle ();
            var progress = 1.0 - manager.renderer.hide_progress;
            

            cursor_region.height = int.max (1, (int) (progress * DEFAULT_HEIGHT));
            cursor_region.y = monitor_geo.y;

            if (manager.settings.enable_slim_mode)
            {
                Gtk.Allocation size;
                manager.window.get_allocation (out size);

                cursor_region.width = size.width;
                cursor_region.x = X;
            }
            else
            {
                cursor_region.width = monitor_geo.width;
                cursor_region.x = monitor_geo.x;
            }

            return cursor_region;
        }
    }

}