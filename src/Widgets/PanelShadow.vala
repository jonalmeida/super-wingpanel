// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//  
//  Copyright (C) 2011-2012 Wingpanel Developers
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

public class SuperWingpanel.Widgets.PanelShadow : Granite.Widgets.CompositedWindow {
    private const string DEFAULT_THEME = """
        .panel-shadow {
            background-color: @transparent;
            background-image: -gtk-gradient (linear,
                             left top, left bottom,
                             from (alpha (#000, 0.3)),
                             to (alpha (#000, 0.0)));
        }
    """;

    public PanelShadow () {
        skip_taskbar_hint = true;

        set_type_hint (Gdk.WindowTypeHint.DOCK);
        set_keep_below (true);
        stick ();

        Granite.Widgets.Utils.set_theming (this, DEFAULT_THEME, StyleClass.SHADOW,
                                           Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK);
    }

    protected override bool draw (Cairo.Context cr) {
        Gtk.Allocation size;
        get_allocation (out size);

        get_style_context ().render_background (cr, size.x, size.y, size.width, size.height);

        return true;
    }

    public void update_size_and_position (int x, int y, int w, int h) {
        set_size_request (w, h);
        move (x, y);
    }
}
