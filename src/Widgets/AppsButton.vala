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
//

namespace SuperWingpanel.Widgets {

    public class AppsButton : IndicatorButton {
        private bool _active = false;
        public bool active {
            get {
                return _active;
            }
            set {
                _active = value;
                update_state_flags ();
            }
        }

        private Services.AppLauncherService? launcher_service = null;
        private Services.Settings settings;

        private Gtk.Label _label;
        private Gtk.Image _image;

        public AppsButton (Services.Settings settings) {
            this.settings = settings;
            this.can_focus = true;

            _label = new Gtk.Label (_("Applications"));
            _image = new Gtk.Image ();
                    
            set_widget (WidgetSlot.IMAGE, _image);
            active = false;

            var style_context = get_style_context ();
            style_context.add_class (StyleClass.APP_BUTTON);

            launcher_service = new Services.AppLauncherService (settings);
            launcher_service.launcher_state_changed.connect (on_launcher_state_changed);

            settings.notify["show-launcher"].connect (on_show_launcher_changed);
            settings.notify["launcher-text-override"].connect (on_launcher_text_override_changed);

            on_show_launcher_changed ();
            on_launcher_text_override_changed ();
        }

        private void on_launcher_state_changed (bool visible) {
            debug ("Launcher visibility changed to %s", visible.to_string ());
            active = visible;
        }

        public void on_launcher_text_override_changed (){
            debug ("text override: %s", settings.launcher_text_override);
            if (settings.launcher_text_override == "") {
                _label.set_text (_("Applications"));
                set_widget (WidgetSlot.LABEL, _label);
            }
            else 
            {
                var file = File.new_for_path (settings.launcher_text_override);
                if (file.query_exists ()) {
                    _image.set_from_file (settings.launcher_text_override);
                    set_widget (WidgetSlot.IMAGE, _image);
                } else {
                    _label.set_markup (settings.launcher_text_override);
                    set_widget (WidgetSlot.LABEL, _label);
                }
            }
                
        }

        public override bool button_press_event (Gdk.EventButton event) {
            launcher_service.launch_launcher ();
            return true;
        }

        /**
         * Make sure the menuitem appears to be selected even if the focus moves
         * to the client launcher app being displayed.
         */
        public override void state_flags_changed (Gtk.StateFlags flags) {
            update_state_flags ();
        }

        private void update_state_flags () {
            const Gtk.StateFlags ACTIVE_FLAGS = Gtk.StateFlags.PRELIGHT;

            if (active)
                set_state_flags (ACTIVE_FLAGS, true);
            else
                unset_state_flags (ACTIVE_FLAGS);
        }

        private void on_show_launcher_changed () {

            bool visible = settings.show_launcher;
            set_no_show_all (!visible);

            if (visible)
                show_all ();
            else
                hide ();
        }
    }
}
