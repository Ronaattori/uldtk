package misc;

import haxe.DynamicAccess;
import thx.csv.Csv;
import cdb.Sheet;
import js.jquery.Event;
import ui.modal.ContextMenu;
import cdb.Data.Column;
import js.jquery.JQuery;

typedef CastleCallbacks = {
    var ?onColumnAdd: Column -> Void;
    var ?onColumnDelete: Column -> Void;
    var ?onColumnUpdate: Column -> Void;
    var ?onLineAdd: (Dynamic, Int) -> Void;
    var ?onLineDelete: Int -> Void;
    var ?onDisplayIconUpdate: String -> Void;
    var ?onDisplayColumnUpdate: String -> Void;
}

class CastleWrapper {

	public var sheet:Sheet;
    public var callbacks: CastleCallbacks;
    
	public function new(sheet: Sheet) {
		this.sheet = sheet;
        this.callbacks = {};
    }

	public function createHeaderContextMenu(?jNear:js.jquery.JQuery, ?openEvent:js.jquery.Event, column:Column) {
        var jEventTarget = jNear!=null ? jNear : new J(openEvent.target);
        var ctx = new ContextMenu(jEventTarget);
        ctx.add({
            label: new LocaleString("Add column"),
            cb: () -> new ui.modal.dialog.CastleColumn(sheet, (c) -> {
                if (this.callbacks.onColumnAdd != null ) this.callbacks.onColumnAdd(c);
            })
        });
        ctx.add({
            label: new LocaleString("Add line"),
            cb: () -> addLine()
        });

        // The rest are only for existing columns
        if (column == null) {
            return ctx;
        }

        ctx.add({
            label: new LocaleString("Edit column"),
            cb: () -> new ui.modal.dialog.CastleColumn(sheet, column, (c) -> {
                if (this.callbacks.onColumnUpdate != null) this.callbacks.onColumnUpdate(c);
            })
        });
        switch column.type {
            case TString:
                var displayCol = sheet.props.displayColumn;
                ctx.add({
                    label: new LocaleString("Set as display name"),
                    sub: new LocaleString(displayCol == column.name ? "Enabled" : "Disabled"),
                    cb: () -> {
                        sheet.props.displayColumn = displayCol == column.name ? null : column.name;
                        if (this.callbacks.onDisplayColumnUpdate != null) this.callbacks.onDisplayColumnUpdate(sheet.props.displayColumn);
                    }
                });
            case TTileLayer, TTilePos, TImage:
                var displayIcon = sheet.props.displayIcon;
                ctx.add({
                    label: new LocaleString("Set as display icon"),
                    sub: new LocaleString(displayIcon == column.name ? "Enabled" : "Disabled"),
                    cb: () -> {
                        sheet.props.displayIcon = displayIcon == column.name ? null : column.name;
                        if (this.callbacks.onDisplayIconUpdate != null) this.callbacks.onDisplayIconUpdate(sheet.props.displayIcon);
                    }
                });
            case _:
        }
        ctx.add({
            label: L._Delete(),
            cb: () -> {
                sheet.deleteColumn(column.name);
                if (this.callbacks.onColumnDelete != null) this.callbacks.onColumnDelete(column);
            }
        });
        return ctx;
    };

	// Add a row before or after specified RowComponent
    public function addLine(?index:Int) {
        var line = sheet.newLine(index);
        if (this.callbacks.onLineAdd != null) this.callbacks.onLineAdd(line, index);
        return line;
	}

    public function deleteLine(index:Int) {
        sheet.deleteLine(index);
        if (this.callbacks.onLineDelete != null) this.callbacks.onLineDelete(index);
    }
    public function moveLine(line:Dynamic, fromIndex:Int, toIndex:Int) {
		sheet.lines.splice(fromIndex, 1); // Remove the original item
		sheet.lines.insert(toIndex, line); // Add the same data to the new position
	}
	public function moveColumn(c:Column, fromIndex:Int, toIndex:Int) {
		sheet.columns.splice(fromIndex, 1); // Remove the original item
		sheet.columns.insert(toIndex, c); // Add the same data to the new position
	}

	public static function importSheet(type:String, absPath:String) {
		var fileContent = NT.readFileString(absPath);
		var table_name = absPath.split("/").pop();
		var data:Array<Array<Dynamic>> = Csv.decode(fileContent);
		var keys:Array<String> = data[0].map(Std.string);
		data.shift(); // Remove keys from the array

		var columns = [];
		for (key in keys) {
			var col:Column = {
				name: key,
				type: TString,
				typeStr: null
			}
			// columns.push(createColumnDef(col));
			columns.push(col);
		}
		var rows = [];
		for (row in data) {
			var obj:DynamicAccess<String> = {};
			for (i => val in row) {
				if (i > keys.length)
					continue; // TODO Is this the desired behaviour to handle extra values on rows?
				obj.set(keys[i], val);
			}
			rows.push(obj);
		}
		var s = Editor.ME.project.database.createSheet(table_name);
		for (c in columns) {
			s.addColumn(c);
		}
		for (l in rows) {
			s.lines.push(l);
		}
		return s;
	}

}