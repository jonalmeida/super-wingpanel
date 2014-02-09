// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2013 Wingpanel Developers
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

using SuperWingpanel.Drawing;

namespace SuperWingpanel.Services {
    public class Settings : Granite.Services.Settings {

        public PanelPosition slim_panel_position { get; set; }
        public PanelEdgeShape slim_panel_edge { get; set; }

        public HideType hide_mode { get; set; }

       
        public string[] blacklist { get; set; }
        public bool show_datetime_in_tray { get; set; }
        public bool enable_slim_mode { get; set; }
        public bool show_launcher { get; set; }
        public bool slim_panel_separate_launcher { get; set; }
        public int slim_panel_margin { get; set; }
        public string default_launcher { get; set; }
        public string launcher_text_override { get; set; }
        public string[] indicator_order { get; set; }
        public bool show_window_controls { get; set; }

        public int UnhideDelay = 200;
        public int hide_time = 400;
        

        public Settings () {
            base ("org.pantheon.desktop.super-wingpanel");
        }
    }
}
