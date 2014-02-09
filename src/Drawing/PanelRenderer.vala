//
//  Copyright (C) 2011-2013 Wingpanel Developers
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

using Cairo;
using Gdk;
using Gtk;
using Gee;

using SuperWingpanel.Services;
using SuperWingpanel.Widgets;

namespace SuperWingpanel.Drawing
{

    public enum PanelEdgeShape {
        SLANTED = 0,
        SQUARED = 1,
        CURVED_1 = 2,
        CURVED_2 = 3,
        CURVED_3 = 4
    }
    
    /**
     * Handles all of the drawing for a panel.
     */
    public class PanelRenderer : AnimatedRenderer
    {
        public WindowManager manager { private get; construct; }
        
        public double hide_progress { get; private set; }
        
        DateTime last_hide = new DateTime.from_unix_utc (0);
        
        DateTime frame_time = new DateTime.from_unix_utc (0);

        public const int SLIM_PANEL_EDGE_PADDING = 10;


        public PanelRenderer (WindowManager manager)
        {
            GLib.Object (manager: manager);
        }


        public void initialize ()
            requires (manager.window != null)
        {
            set_widget (manager.window);
            
            manager.hide_manager.notify["Hidden"].connect (hidden_changed);
            manager.settings.notify["slim-panel-edge"].connect (manager.window.queue_draw);
            manager.settings.notify["slim-panel-position"].connect (manager.window.queue_draw);

        }

        ~DockRenderer ()
        {
            manager.hide_manager.notify["Hidden"].disconnect (hidden_changed);
            manager.settings.notify["slim-panel-edge"].disconnect (manager.window.queue_draw);
            manager.settings.notify["slim-panel-position"].disconnect (manager.window.queue_draw);
        }


        public void draw_panel (Cairo.Context cr) 
        {
            frame_time = new DateTime.now_utc ();

            var hide_time = manager.settings.hide_time;
            var diff = double.min (1, frame_time.difference (last_hide) / (double) (hide_time * 1000));
            hide_progress = (manager.hide_manager.Hidden ? diff : 1.0 - diff);

            
            if (manager.settings.hide_mode != HideType.INTELLISLIM)
            {
                manager.window.update_size_and_position ();
                double opacity = 1 - hide_progress;
                manager.window.set_opacity (opacity);
                manager.shadow.set_opacity (opacity);
            }
            else
            {
                if (hide_progress <= 0.5) {      // first half, fade out
                    double opacity = 1 - 2 * hide_progress;
                    manager.window.set_opacity (opacity);
                    manager.shadow.set_opacity (opacity);
                } else {        // second half, move and fade in
                    double opacity = 2 * (hide_progress - 0.5);
                    manager.window.set_opacity (opacity);
                    manager.shadow.set_opacity (opacity);
                }
                manager.window.update_size_and_position ();

            }

                

            Gtk.Allocation size;
            manager.window.get_allocation (out size);

            var ctx = manager.window.get_draw_style_context ();
            ctx.render_background (cr, size.x, size.y, size.width, size.height);

            var child = manager.window.get_child ();

            if (child != null)
                manager.window.propagate_draw (child, cr);

            if (!manager.shadow.visible)
                manager.shadow.show_all ();

            if (manager.settings.enable_slim_mode || (manager.settings.hide_mode == HideType.INTELLISLIM && hide_progress >= 0.5))
            {
                draw_slim_edges (cr);
            }
        }

        void draw_slim_edges (Cairo.Context context)
        {
            Gtk.Allocation size;
            manager.window.get_allocation (out size);
        
            // bg is already drawn by the css file, we need to specify which areas should be hidden
            draw_mask(context, 0, 0, size.width, size.height, SLIM_PANEL_EDGE_PADDING);
            context.clip ();
        
            context.set_source_rgba (1.0, 0.0, 0.0, 0.0);
            context.set_operator (Cairo.Operator.SOURCE);
            context.paint ();
        }

        private void draw_mask(Cairo.Context context, double x, double y, double width, double height, double clip_amount) {
            // This shape is what will be erased
            context.move_to (x, y);

            if (manager.settings.slim_panel_position == PanelPosition.FLUSH_LEFT)
                context.move_to (x, y + height);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.SLANTED)
                context.line_to (x + clip_amount, y + height);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.SQUARED)
                context.line_to (x, y + height);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.CURVED_1)
                context.curve_to (x + clip_amount, y, x, y + height, x + clip_amount, y + height);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.CURVED_2)
                context.curve_to (x, y, x + clip_amount, y, x + clip_amount, y + height);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.CURVED_3)
                context.curve_to (x, y + height - (clip_amount / 2) , x + (clip_amount / 2), y + height, x + clip_amount, y + height);
            
            context.line_to (x + width - clip_amount, y + height);
            
            if (manager.settings.slim_panel_position == PanelPosition.FLUSH_RIGHT)
                context.line_to (x + width, y + height);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.SLANTED)
                context.line_to (x + width, y);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.SQUARED)
                context.line_to (x + width, y + height);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.CURVED_1)
                context.curve_to (x + width, y + height, x + width - clip_amount, y, x + width, y);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.CURVED_2)
                context.curve_to (x + width - clip_amount, y + height, x + width - clip_amount, y, x + width, y);
            else if (manager.settings.slim_panel_edge == PanelEdgeShape.CURVED_3)
                context.curve_to (x + width - (clip_amount / 2), y + height-1, x + width, y + height - (clip_amount / 2), x + width, y);
                
            context.line_to (x + width, y + height);
            context.line_to (x, y + height);
            context.line_to (x, y);
        }

        void hidden_changed ()
        {
            var now = new DateTime.now_utc ();
            var diff = now.difference (last_hide);
            var hide_time = manager.settings.hide_time;


            if (diff < hide_time * 1000)
                last_hide = now.add_seconds ((diff - hide_time * 1000) / 1000000.0);
            else
                last_hide = now;

            animated_draw ();
        }

        protected override bool animation_needed (DateTime render_time)
        {
            if (render_time.difference (last_hide) <= manager.settings.hide_time * 1000)
                return true;


            return false;
        }

    }
}