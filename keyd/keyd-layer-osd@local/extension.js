import Gio from 'gi://Gio';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const DBUS_PATH = '/org/gnome/Shell/Extensions/KeydLayerOsd';
const DBUS_INTERFACE = `
<node>
  <interface name="org.gnome.Shell.Extensions.KeydLayerOsd">
    <method name="ShowLayer">
      <arg name="layer" type="s" direction="in"/>
    </method>
  </interface>
</node>`;

export default class KeydLayerOsd extends Extension {
    enable() {
        this._icon = new Gio.ThemedIcon({
            name: 'input-keyboard-symbolic',
        });

        this._dbusObject = Gio.DBusExportedObject.wrapJSObject(
            DBUS_INTERFACE, this);
        this._dbusObject.export(Gio.DBus.session, DBUS_PATH);
    }

    disable() {
        this._dbusObject.unexport();
        this._dbusObject = null;
        this._icon = null;
    }

    ShowLayer(layer) {
        if (!['NAV', 'UTILITY', 'MAIN'].includes(layer)) {
            throw new Error(`Unknown keyboard layer: ${layer}`);
        }

        Main.osdWindowManager.showAll(this._icon, layer, null, 1);
    }
}
