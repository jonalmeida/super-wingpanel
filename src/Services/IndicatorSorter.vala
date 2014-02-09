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

/**
 * Indicator sorter class.
 *
 * This class is composed of static methods because compare_func() needs
 * to be static in order to work properly, since instance methods cannot
 * be passed as CompareFuncs.
 */
public class SuperWingpanel.Services.IndicatorSorter {
    private struct IndicatorOrderNode {
        public string name;        // name of indicator (library)
        public string? entry_name; // name of entry (menu item)
    }

    private const IndicatorOrderNode[] DEFAULT_ORDER = {
        { "libdatetime.so", null },                      // date time widget
        { "libapplication.so", null },                   // indicator-application (App indicators)
        { "libapplication.so", "keyboard" },             // Keyboard layout selector (old)
        { "libapplication.so", "gsd-keyboard-xkb" },     // keyboard layout selector
        { "libsoundmenu.so", null },                     // indicator-sound
        { "libnetwork.so", null },                       // indicator-network
        { "libnetworkmenu.so", null },                   // indicator-network
        { "libapplication.so", "nm-applet" },            // network manager
        { "libbluetooth.so", null },                     // indicator-bluetooth
        { "libapplication.so", "bluetooth-manager" },    // indicator-gnome-bluetooth (old)
        { "libprintersmenu.so", null },                  // indicator-printers
        { "libsyncindicator.so", null },                 // indicator-sync
        { "libpower.so", null },                         // indicator-power
        { "libmessaging.so", null },                     // indicator-messages
        { "libsession.so", null },                       // indicator-session
        { "libsession.so", "indicator-session-users" },  // indicator-session
        { "libsession.so", "indicator-session-devices" } // indicator-session
    };
    private static IndicatorOrderNode[] CUSTOM_ORDER = null;

    public static void set_order(string[] new_order) {
        
        CUSTOM_ORDER = new IndicatorOrderNode[new_order.length];

        try 
        {
            for (int i=0; i<new_order.length; i++){
                string item = new_order[i];

                var node = IndicatorOrderNode ();
                if (item.contains ("|")) {
                    string[] item_parts = item.split_set ("|", 2);
                    node.name = item_parts[0];
                    node.entry_name = item_parts[1];
                } else {
                    node.name = item;
                }
                CUSTOM_ORDER[i] = node;
            }
        }
        catch (Error e){
            error ("Custom indicator order format was invalid");
            CUSTOM_ORDER = null;
        }
    }

    public static int compare_func (IndicatorWidget? a, IndicatorWidget? b) {
        if (a == null)
            return (b == null) ? 0 : -1;

        if (b == null)
            return 1;

        var order_a = get_order_node (a);
        var order_b = get_order_node (b);

        int order = get_order (order_a) - get_order (order_b);

        if (order == 0)
            order = compare_entries_by_name (order_a, order_b);

        return order.clamp (-1, 1);
    }

    /**
     * Whenever two different entries belong to the same indicator object (lib)
     * and are not part of the default order list, we sort them using their
     * individual name hints.
     */
    private static int compare_entries_by_name (IndicatorOrderNode a, IndicatorOrderNode b) {
        return strcmp (a.entry_name, b.entry_name);
    }

    private static IndicatorOrderNode get_order_node (IndicatorWidget widget) {
        var order_node = IndicatorOrderNode ();

        order_node.name = widget.get_indicator ().get_name ();
        order_node.entry_name = widget.get_entry_name ();

        return order_node;
    }

    private static int get_order (IndicatorOrderNode node) {
        int best_match = 0;

        IndicatorOrderNode[] ORDER = (CUSTOM_ORDER != null) ? CUSTOM_ORDER : DEFAULT_ORDER;

        for (int i = 0; i < ORDER.length; i++) {
            var current_node = ORDER[i];

            if (current_node.name == node.name) { // name of lib matches the one in DEFAULT_ORDER
                if (current_node.entry_name == node.entry_name) {
                    best_match = i;
                    break; // entry name also matches. Exact same indicator.
                } else if (current_node.entry_name == null) {
                    best_match = i;
                }
            }
        }

        return best_match;
    }
}
