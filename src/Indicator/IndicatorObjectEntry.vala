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

namespace SuperWingpanel.Backend
{
    public class IndicatorObjectEntry: Widgets.IndicatorButton, IndicatorWidget {
        private unowned Indicator.ObjectEntry entry;
        private IndicatorIface indicator;

        // used for drawing
        private Gtk.Window menu;
        private Granite.Drawing.BufferSurface buffer;
        private int w = -1;
        private int h = -1;
        private int arrow_height = 10;
        private int arrow_width = 20;
        private double x = 10.5;
        private double y = 10.5;
        private int radius = 5;

        private const string MENU_STYLESHEET = """
            .menu {
                background-color:@transparent;
                border-color:@transparent;
                -unico-inner-stroke-width: 0;
                background-image:none;
             }
             .popover_bg {
               background-color:#fff;
             }
         """;

        public IndicatorObjectEntry (Indicator.ObjectEntry entry, IndicatorIface indicator) {
            this.entry = entry;
            this.indicator = indicator;

            var image = entry.image;
            if (image != null && image is Gtk.Image)
                set_widget (WidgetSlot.IMAGE, image);

            var label = entry.label;
            if (label != null && label is Gtk.Label)
                set_widget (WidgetSlot.LABEL, label);

            show ();

            if (entry.menu == null) {
                string indicator_name = indicator.get_name ();
                string entry_name = get_entry_name ();

                critical ("Indicator: %s (%s) has no menu widget.", indicator_name, entry_name);
                return;
            }
            
            if (entry.menu.get_attach_widget() != null)
                entry.menu.detach();

            set_submenu (entry.menu);

            setup_drawing ();

            entry.menu.get_children ().foreach (setup_margin);
            entry.menu.insert.connect (setup_margin);
        }

        public IndicatorIface get_indicator () {
            return indicator;
        }

        public string get_entry_name () {
            return entry.name_hint ?? "";
        }

        private void setup_margin (Gtk.Widget widget) {
            widget.margin_left = 10;
            widget.margin_right = 9;
        }

        private void setup_drawing () {
            setup_entry_menu_parent ();

            buffer = new Granite.Drawing.BufferSurface (100, 100);

            entry.menu.margin_top = 28;
            entry.menu.margin_bottom = 18;

            Granite.Widgets.Utils.set_theming (entry.menu, MENU_STYLESHEET, null,
                                               Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            menu = new Granite.Widgets.PopOver ();

            Granite.Widgets.Utils.set_theming (menu, MENU_STYLESHEET,
                                               Granite.StyleClass.POPOVER_BG,
                                               Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        private void setup_entry_menu_parent () {
            var menu_parent = entry.menu.get_parent ();
            menu_parent.app_paintable = true;
            menu_parent.set_visual (Gdk.Screen.get_default ().get_rgba_visual ());

            menu_parent.draw.connect (entry_menu_parent_draw_callback);
        }

        private bool entry_menu_parent_draw_callback (Cairo.Context ctx) {
            var new_w  = entry.menu.get_parent ().get_allocated_width ();
            var new_h = entry.menu.get_parent ().get_allocated_height ();

            if (new_w != w || new_h != h) {
                w = new_w;
                h = new_h;

                buffer = new Granite.Drawing.BufferSurface (w, h);
                cairo_popover (w, h);

                var cr = buffer.context;

                // shadow
                cr.set_source_rgba (0, 0, 0, 0.5);
                cr.fill_preserve ();
                buffer.exponential_blur (6);
                cr.clip ();

                // background
                menu.get_style_context ().render_background (cr, 0, 0, w, h);
                cr.reset_clip ();

                // border
                cairo_popover (w, h);
                cr.set_operator (Cairo.Operator.SOURCE);
                cr.set_line_width (1);
                Gdk.cairo_set_source_rgba (cr, menu.get_style_context ().get_border_color (Gtk.StateFlags.NORMAL));
                cr.stroke ();
            }

            // clear surface to transparent
            ctx.set_operator (Cairo.Operator.SOURCE);
            ctx.set_source_rgba (0, 0, 0, 0);
            ctx.paint ();

            // now paint our buffer on
            ctx.set_source_surface (buffer.surface, 0, 0);
            ctx.paint ();

            return false;
        }

        private void cairo_popover (int w, int h) {
            w = w - 20;
            h = h - 20;

            // Get some nice pos for the arrow
            var offs = 30;
            int p_x;
            int w_x;
            Gtk.Allocation alloc;
            this.get_window ().get_origin (out p_x, null);
            this.get_allocation (out alloc);

            entry.menu.get_window ().get_origin (out w_x, null);

            offs = (p_x + alloc.x) - w_x + this.get_allocated_width () / 4;
            if (offs + 50 > (w + 20))
                offs = (w + 20) - 15 - arrow_width;
            if (offs < 17)
                offs = 17;

            buffer.context.arc (x + radius, y + arrow_height + radius, radius, Math.PI, Math.PI * 1.5);
            buffer.context.line_to (offs, y + arrow_height);
            buffer.context.rel_line_to (arrow_width / 2.0, -arrow_height);
            buffer.context.rel_line_to (arrow_width / 2.0, arrow_height);
            buffer.context.arc (x + w - radius, y + arrow_height + radius, radius, Math.PI * 1.5, Math.PI * 2.0);

            buffer.context.arc (x + w - radius, y + h - radius, radius, 0, Math.PI * 0.5);
            buffer.context.arc (x + radius, y + h - radius, radius, Math.PI * 0.5, Math.PI);

            buffer.context.close_path ();
        }

        public override bool scroll_event (Gdk.EventScroll event) {
            var direction = Indicator.ScrollDirection.UP;
            double delta = 0;

            switch (event.direction) {
                case Gdk.ScrollDirection.UP:
                    delta = event.delta_y;
                    direction = Indicator.ScrollDirection.UP;
                    break;
                case Gdk.ScrollDirection.DOWN:
                    delta = event.delta_y;
                    direction = Indicator.ScrollDirection.DOWN;
                    break;
                case Gdk.ScrollDirection.LEFT:
                    delta = event.delta_x;
                    direction = Indicator.ScrollDirection.LEFT;
                    break;
                case Gdk.ScrollDirection.RIGHT:
                    delta = event.delta_x;
                    direction = Indicator.ScrollDirection.RIGHT;
                    break;
                default:
                    break;
            }

            entry.parent_object.entry_scrolled (entry, (uint) delta, direction);

            return false;
        }
    }
}