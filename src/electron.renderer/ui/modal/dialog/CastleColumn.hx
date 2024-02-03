package ui.modal.dialog;

import format.abc.Data.ABCData;
import js.jquery.JQuery;
import js.html.Option;
import cdb.Sheet;
import cdb.Data;

class CastleColumn extends ui.modal.Dialog {
	var onConfirm : Null<Column->Void>;
	var sheet : Sheet;
	var column : Null<Column>;
	var jExtra : JQuery;
	var jExtraName : JQuery;
	var jExtraValue : JQuery;

	public function new(sheet:cdb.Sheet, ?column:Column, ?onConfirm:Column->Void) {
		super();
		this.onConfirm = onConfirm;
		this.sheet = sheet;
		this.column = column;
		loadTemplate("castleColumn");

		var jSelect = jContent.find("select[name=type]");
		jExtra = jContent.find("#extra-holder");
		jExtraName = jExtra.children().first();
		jExtraValue = jExtra.children().last();
		var jConfirm = jContent.find(".confirm");
		var jCancel = jContent.find(".cancel");

		jCancel.click( _-> {
			close();
		});

		jSelect.on("change", (e) -> {
			switch (jSelect.val()) {
				case "ref":
					createRefSelector();
				case "enum":
					createEnumValues();
				case _:
					var x = jExtra.hide();
			}
		});

		if (column == null) {
			jConfirm.click( _-> {
				var c = getColumn();
				var result = sheet.addColumn(c);
				sheet.sync();
				if (result != null) {
					Notification.error(result);
				}  else {
					Notification.success("Column created succesfully");
					close();
					onConfirm(c);
				}
			});
		} else {
			editColumn(column);
			jConfirm.click( _-> {
				var newColumn = getColumn();
				var result = sheet.base.updateColumn(sheet, column, newColumn);
				if (result != null) {
					Notification.error(result);
				}  else {
					Notification.success("Column edited succesfully");
					close();
					onConfirm(newColumn);
				}
			});
		}
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);
		switch keyCode {
			case K.ENTER:
				//column == null ? createColumn() : close();

			case _:
		}
	}

	override function onClickMask() {
		super.onClickMask();

		// if( onCancel!=null )
		// 	onCancel();
	}

	function createEnumValues() {
		prepareExtras("Possible values");
		var input = new J("<input type='text'/>");
		input.attr("placeholder", "value1,value2,value3...");
		input.appendTo(jExtraValue);
		if (column != null) {
			input.val(column.type.getParameters()[0].join(","));
		}
	}

	function createRefSelector() {
		prepareExtras("Sheet");
		var select = new J("<select/>");
		var refSheet = null;
		if (column != null) {
			refSheet = sheet.base.getSheet(sheet.base.typeStr(column.type));
		}
		for (s in sheet.base.sheets.filter(s -> !s.props.hide)) {
			// If a ref sheet was found with typeStr, and its name matches this sheet
			var selected = refSheet != null && refSheet.name == s.name ? true : false;
			select.append(new Option(s.name, s.name, false, selected));
		}
		select.appendTo(jExtraValue);
	}
	function prepareExtras(name:String) {
		jExtra.show();
		jExtraValue.empty();
		jExtraName.html(name);
	}

	function editColumn(c:Column) {
		jContent.find("input[name=name]").val(c.name);
		jContent.find("select[name=type]").val(c.type.getName().substr(1).toLowerCase()).trigger("change");
		jContent.find("input[name=required]").prop("checked", !column.opt);
	}

	function getColumn() {
		var name = jContent.find("input[name=name]").val();
		var type = getType(jContent.find("select[name=type]").val());
		var c:Column = {
			name: name,
			type: type,
			typeStr: null
		};
		c.opt = !jContent.find("input[name=required]").prop("checked");

		return c;
	}

	function getType(type:String) {
		// TODO implement all types
		var type:ColumnType = switch(type) {
			case "id": TId;
			case "int": TInt;
			case "float": TFloat;
			case "string": TString;
			case "bool": TBool;
			case "enum":
				TImage;
				// var vals = StringTools.trim(v.values).split("\n");
				// vals = [for ( v in vals) for (e in v.split(",")) e];
				// vals.removeIf(function(e) {
				// 	return StringTools.trim(e) == "";
				// });
				// if( vals.length == 0 ) {
				// 	error("Missing value list");
				// 	return null;
				// }
				var values:String = jExtraValue.find("input").val();
				return TEnum([for( f in values.split(",") ) StringTools.trim(f)]);
			case "flags":
				TImage;
				// var vals = StringTools.trim(v.values).split("\n");
				// vals = [for ( v in vals) for (e in v.split(",")) e];
				// vals.removeIf(function(e) {
				// 	return StringTools.trim(e) == "";
				// });
				// if( vals.length == 0 ) {
				// 	error("Missing value list");
				// 	return null;
				// }
				// if( vals.length > 30 ) {
				// 	error("Too many possible values");
				// 	return null;
				// }
				// TFlags([for( f in vals ) StringTools.trim(f)]);
			case "ref":
				var s = jExtraValue.find("select").val();
				return TRef(s);
			case "image":
				TImage;
			case "list":
				TList;
			case "custom":
				TList;
				// var t = base.getCustomType(v.ctype);
				// if( t == null ) {
				// 	error("Type not found");
				// 	return null;
				// }
				// TCustom(t.name);
			case "color":
				TColor;
			case "layer":
				TColor;
				// var s = base.sheets[Std.parseInt(v.sheet)];
				// if( s == null ) {
				// 	error("Sheet not found");
				// 	return null;
				// }
				// TLayer(s.name);
			case "file":
				TFile;
			case "tilepos":
				TTilePos;
			case "tilelayer":
				TTileLayer;
			case "dynamic":
				TDynamic;
			case "properties":
				TProperties;
			case _:
				null;
		};
		return type;
	}
}