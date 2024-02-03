package misc;

import cdb.Data.ColumnType;
import data.def.TilesetDef;
import ldtk.Json.TilesetRect;
import cdb.Types.TilePos;
import ui.modal.dialog.TextEditor;
import haxe.Json;
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
	public var lines:Array<Dynamic>;
    public var callbacks: CastleCallbacks;
    
	public function new(sheet: Sheet, ?parentLine: Dynamic) {
		this.sheet = sheet;
        this.callbacks = {};
		if (parentLine) {
			this.lines = Reflect.field(parentLine, sheet.getParent().c);
		} else {
			this.lines = sheet.getLines();
		}
		if (this.lines == null)
			this.lines = [];
    }

    //
    // Utility functions
    //

    // Run onReady when element has been added and is visible in the DOM
    function waitForElementReady(element:JQuery, onReady: JQuery -> Void) {
        var mutationObserver = new js.html.MutationObserver((mutations, observer) -> { 
            var node = cast (element.get(0), js.html.Node);
            if (js.Browser.document.contains(node)) {
                onReady(new J(node.parentElement));
                observer.disconnect();
            }
        });
        mutationObserver.observe(js.Browser.document, {
            childList: true,
            subtree: true
        });
    }
    function findLineById(id: Dynamic, ?fromSheet: Sheet){
        var s = fromSheet == null ? sheet : fromSheet;
        var idCol = s.idCol.name;
        return s.lines.filter((line) -> Reflect.field(line, idCol) == id)[0];
    }
	public function tilePosToHtmlImg(tilePos:TilePos) {
        var td = getTilesetDef(tilePos);
		var img = td.createTileHtmlImageFromRect(tilePosToTilesetRect(tilePos, td));
		return img;
	}

	// LDTK uses pixels for the grid and Castle how many'th tile it is
    // TilesetRect == LDtk thing
    // TilePos == Castle thing
	public static function tilePosToTilesetRect(tilePos:TilePos, td:TilesetDef):TilesetRect {
		var hei = tilePos.height != null ? tilePos.height : 1;
		var wid = tilePos.width != null ? tilePos.width : 1;
		var tilesetRect:TilesetRect = {
			tilesetUid: td.uid,
			h: hei * td.tileGridSize,
			w: wid * td.tileGridSize,
			y: tilePos.y * td.tileGridSize,
			x: tilePos.x * td.tileGridSize,
		};
		return tilesetRect;
	}

	public static function tilesetRectToTilePos(tilesetRect:TilesetRect, td:TilesetDef) {
		var tilePos:TilePos = {
			file: td.relPath,
			size: td.tileGridSize,
			height: Std.int(tilesetRect.h / td.tileGridSize),
			width: Std.int(tilesetRect.w / td.tileGridSize),
			y: Std.int(tilesetRect.y / td.tileGridSize),
			x: Std.int(tilesetRect.x / td.tileGridSize),
		}
		return tilePos;
	}
    public function getTilesetDef(tilePos: TilePos) {
		if (tilePos.file == null)
			return null;
		return Editor.ME.project.defs.getTilesetDefFrom(tilePos.file);
    }

	public static function createTilePos(td:TilesetDef) {
		var tilePos:TilePos = {
			file: td.relPath,
			size: td.tileGridSize,
			height: null,
			width: null,
			y: 0,
			x: 0,
		};
		return tilePos;
	}
    


    //
    // Stuff to interact with the database
    //
	public function createHeaderContextMenu(?jNear:js.jquery.JQuery, ?openEvent:js.jquery.Event, column:Column) {
        var jEventTarget = jNear!=null ? jNear : new J(openEvent.target);
        var ctx = new ContextMenu(jEventTarget);
        ctx.addAction({
            label: new LocaleString("Add column"),
            cb: () -> new ui.modal.dialog.CastleColumn(sheet, (c) -> {
                if (this.callbacks.onColumnAdd != null ) this.callbacks.onColumnAdd(c);
            })
        });
        ctx.addAction({
            label: new LocaleString("Add line"),
            cb: () -> addLine()
        });

        // The rest are only for existing columns
        if (column == null) {
            return ctx;
        }

        ctx.addAction({
            label: new LocaleString("Edit column"),
            cb: () -> new ui.modal.dialog.CastleColumn(sheet, column, (c) -> {
                if (this.callbacks.onColumnUpdate != null) this.callbacks.onColumnUpdate(c);
            })
        });
        switch column.type {
            case TString:
                var displayCol = sheet.props.displayColumn;
                ctx.addAction({
                    label: new LocaleString("Set as display name"),
                    subText: new LocaleString(displayCol == column.name ? "Enabled" : "Disabled"),
                    cb: () -> {
                        sheet.props.displayColumn = displayCol == column.name ? null : column.name;
                        if (this.callbacks.onDisplayColumnUpdate != null) this.callbacks.onDisplayColumnUpdate(sheet.props.displayColumn);
                    }
                });
            case TTileLayer, TTilePos, TImage:
                var displayIcon = sheet.props.displayIcon;
                ctx.addAction({
                    label: new LocaleString("Set as display icon"),
                    subText: new LocaleString(displayIcon == column.name ? "Enabled" : "Disabled"),
                    cb: () -> {
                        sheet.props.displayIcon = displayIcon == column.name ? null : column.name;
                        if (this.callbacks.onDisplayIconUpdate != null) this.callbacks.onDisplayIconUpdate(sheet.props.displayIcon);
                    }
                });
            case _:
        }
        ctx.addAction({
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
        // // If this sheet is a sub, add it to the parent line instead
        // // sheet.newLine adds it to the sheet, so we need to remove it
        var i = index ?? 0;
        if (sheet.getParent() != null) {
            sheet.deleteLine(sheet.lines.indexOf(line));
            this.lines.insert(i, line);
        }
        if (this.callbacks.onLineAdd != null) this.callbacks.onLineAdd(line, i);
        return line;
	}

    public function deleteLine(index:Int) {
        // TODO maybe use the sheet. builtin functions
        this.lines.splice(index, 1);
        if (this.callbacks.onLineDelete != null) this.callbacks.onLineDelete(index);
    }
    public function moveLine(fromIndex:Int, toIndex:Int) {
        // TODO maybe use the sheet. builtin functions
		var line = this.lines.splice(fromIndex, 1)[0]; // Remove the original item
		this.lines.insert(toIndex, line); // Add the same data to the new position
	}
	public function moveColumn(fromIndex:Int, toIndex:Int) {
		var c:Null<Column> = sheet.columns.splice(fromIndex, 1)[0]; // Remove the original item
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

    public function createDynamicEditor(line:Dynamic, column: Column, ?onChange: String -> Void) {
		var curValue =  Reflect.field(line, column.name);
		var jInput = new J("<input type='text'>");
        jInput.val(sheet.base.valToString(TDynamic, curValue));
		var json = Json.stringify(curValue, null, "\t");
        jInput.click((e) -> {
            var te = new TextEditor(json, column.name, null, LangJson, (value) -> {
                    // TODO Handle JSON parsing errors
                    var val = sheet.base.parseDynamic(value);
                    jInput.val(sheet.base.valToString(TDynamic, val));
                    Reflect.setField(line, column.name, val);
                    if (onChange != null) onChange(val);
           });
        });
        return jInput;
    }

    public function createColorEditor(line:Dynamic, column: Column, ?onChange: Int -> Void) {
		var curValue = Reflect.field(line, column.name);
		var jColor = new J("<input type='color'/>");
		jColor.val(C.intToHex(curValue));
		jColor.change( ev->{
            var val = C.hexToInt(jColor.val());
            Reflect.setField(line, column.name, val);
            if (onChange != null) onChange(val);
		});
        waitForElementReady(jColor, (parent) -> misc.JsTools.parseComponents(parent));
		return jColor;
    }
    public function createSelectEditor(line:Dynamic, column: Column, ?onChange: Dynamic -> Void) {
		var curValue = Reflect.field(line, column.name);
        var select = new J("<select class='advanced'>");
		var options:Array<{label:String, value:Dynamic, ?image:TilePos}> = switch (column.type) {
			case TEnum(values):
				var opts = [];
				for (i => value in values) {
					opts.push({
						label: value,
						value: i
					});
				}
				opts;
			case TRef(sheetName):
				var opts = [];
				var refSheet = sheet.base.getSheet(sheetName);
                var idCol = refSheet.idCol.name;
                var iconCol = refSheet.props.displayIcon;
				var displayCol = refSheet.props.displayColumn ?? idCol;
				for (line in refSheet.getLines()) {
					opts.push({
						label: Reflect.field(line, displayCol),
						value: Reflect.field(line, idCol),
                        image: Reflect.field(line, iconCol),
					});
				}
				opts;
			case _:
				throw 'createSelectEditor cannot be used with ${column.type}';
		}
		if (column.opt) {
			select.append(new js.html.Option("-- null --", null, true));
		}
        for (i => option in options) {
            var jOpt = new js.html.Option(option.label, Std.string(i), false, option.value == curValue);
            select.append(jOpt);
            
            if (option.image != null) {
                var tp = option.image;
                var td = getTilesetDef(tp);
                var tilesetRect = tilePosToTilesetRect(tp, td);
                jOpt.setAttribute("tile", haxe.Json.stringify(tilesetRect));

            }
        }
		select.change(e -> {
			var i = Std.parseInt(select.val());
			var value = i != null ? options[i].value : null;
            Reflect.setField(line, column.name, value);

            var advancedSelect = select.parent().find(".advancedSelect");
            if (advancedSelect.length == 1) {
                advancedSelect.children().removeClass("selected");
                advancedSelect.find('[value=${i}]').addClass("selected");
            }
            
            if (onChange != null) onChange(value);
        });
        waitForElementReady(select, (parent) -> misc.JsTools.parseComponents(parent));
        return select;
    }
    public function createListEditor(line: Dynamic, column: Column, ?onChange: Void -> Void) {
		var jInput = new J("<input type='text'>");
		var sub = sheet.getSub(column);
		var str = "[" + Std.string([for (x in sub.columns) x.name]) + "]";
        jInput.val(str);

        jInput.click((e:js.html.Event) -> {
            var target = cast(e.target, js.html.Element);
            var row = target.closest(".tabulator-row");
            if (row.querySelector("#subTabulator") != null) {
                row.querySelector("#subTabulator").remove();
                return;
            }

            var holder = new J("<div id='subTabulator'>");
            holder.addClass("subHolder");
            var table = new J("<div>");

            var subTabulator = new Tabulator(table.get(0), sub, line);

            holder.css("boxSizing", "border-box");
            holder.css("padding", "10px 30px 10px10px");
            holder.css("borderTop", "1px solid #333");
            holder.css("borderBottom", "1px solid #333");

            table.css("border", "3px solid #333");
            table.css("height", "fit-content");
            table.css("width", "fit-content");

            holder.append(table);
            jInput.closest(".tabulator-row").append(holder);
        });

        return jInput;
    }
    public function createTilePosEditor(line: Dynamic, column: Column, ?onChange: TilePos -> Void) {
		var curValue =  Reflect.field(line, column.name);
		var select = JsTools.createTilesetSelect(Editor.ME.project, null, null, false, (uid) -> {
			var td = Editor.ME.project.defs.getTilesetDef(uid);
			var tp = CastleWrapper.createTilePos(td);
			Reflect.setField(line, column.name, tp);
            if (onChange != null) onChange(tp);
		});
		if (curValue == null || (curValue != null && curValue.file == null))
			return select;
		var td = Editor.ME.project.defs.getTilesetDefFrom(curValue.file);
		if (td == null)
			return select;
		var jPicker = JsTools.createTilePicker(td.uid, TileRect, td.getTileIdsFromRect(CastleWrapper.tilePosToTilesetRect(curValue, td)), true, (tileIds) -> {
			var tilesetRect = td.getTileRectFromTileIds(tileIds);
            var tp = CastleWrapper.tilesetRectToTilePos(tilesetRect, td);
			Reflect.setField(line, column.name, tp);
            if (onChange != null) onChange(tp);
		});
		return jPicker;
    }
	public function createCheckboxEditor(line: Dynamic, column:Column, ?onChange: Bool -> Void) {
		var curValue = Reflect.field(line, column.name);
		var jInput = new J("<input type='checkbox'>");
		jInput.prop("checked", curValue);
		jInput.change(d -> {
            var checked: Bool = jInput.prop("checked");
			Reflect.setField(line, column.name, checked);
            if (onChange != null) onChange(checked);
		});
		return jInput;
	}
	public function createInputEditor(line:Dynamic, column: Column, ?onChange: String -> Void) {
		var curValue = Reflect.field(line, column.name);
		var jInput = new J("<input type='text'>");
		jInput.val(curValue);
		jInput.change(e -> {
            var val = jInput.val();
			Reflect.setField(line, column.name, val);
            if (onChange != null) onChange(val);
		});
		return jInput;
	}

}