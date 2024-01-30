package misc.castle;

import haxe.DynamicAccess;

class Line {
    public var sheet: SheetWrapper;
    public var items: DynamicAccess<LineItem>;
    public var display(get, never): String;

    public function new(data: Dynamic, sheet: SheetWrapper) {
        this.sheet = sheet;
        
        var _data: DynamicAccess<Dynamic> = data;
        // this.items = _data.keyValueIterator((k, v) -> new LineItem())
    }

    private function get_display() {
        var l = items.get(sheet.displayColumn);
        var v = l.value;
        if (v == null || v == "") {
            v = "-- Null --";
        }
        return v.toString();
    }
}