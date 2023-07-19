package ui;

import haxe.Json;
import ui.modal.dialog.TextEditor;
import cdb.Data.Column;

class TableDefsForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	public var jWrapper : js.jquery.JQuery;
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jWrapper.find("ul.rowList");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWrapper.find("dl.form");
	var sheet : cdb.Sheet;
	var curLine : Null<Dynamic>;


	public function new(sheet:cdb.Sheet) {
		this.sheet = sheet;
		this.curLine = sheet.lines[0];

		jWrapper = new J('<div class="tableDefsForm"/>');
		jWrapper.html( JsTools.getHtmlTemplate("tableDefsForm"));
		jWrapper.width("750px");

		updateList();
		updateForm();
	}
	public function selectLine(line) {
		curLine = line;
		updateList();
		updateForm();
	}

	public function updateList(){
		jList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jList);
		var jSubList = new J('<ul/>');
		jSubList.appendTo(jLi);

	// 	var pki = td.columns.indexOf(td.primaryKey);
		var displayCol = sheet.props.displayColumn ?? sheet.idCol.name;
		for(line in sheet.lines) {
			var jLi = new J("<li/>");
			jLi.appendTo(jSubList);
			jLi.append('<span class="table">'+Reflect.field(line, displayCol)+'</span>');
			// jLi.data("uid",td.uid);

			if( line==curLine )
				jLi.addClass("active");
			jLi.click( function(_) {
				selectLine(line);
			});
			ui.modal.ContextMenu.addTo(jLi, [
				{
					label: L._Delete(),
					cb: () -> {},
				},
			]);
		}

	// 	// Make list sortable
		JsTools.makeSortable(jSubList, function(ev) {
			// var jItem = new J(ev.item);
			// var fromIdx = project.defs.getTableIndex( jItem.data("uid") );
			// var toIdx = ev.newIndex>ev.oldIndex
			// 	? jItem.prev().length==0 ? 0 : project.defs.getTableIndex( jItem.prev().data("uid") )
			// 	: jItem.next().length==0 ? project.defs.tables.length-1 : project.defs.getTableIndex( jItem.next().data("uid") );

			// var moved = project.defs.sortTableDef(fromIdx, toIdx);
			// selectTable(moved);
			// editor.ge.emit(TilesetDefSorted);
		});
	}
		
	public function updateForm(){
		if( curLine==null ) {
			jForm.hide();
			return;
		}
		jForm.show();
		jForm.empty();
		for (column in sheet.columns) {
			var name = column.name;
			jForm.append('<dt><label for=$name>$name</label></dt><dd></dd>');
			var editor = getEditor(column, curLine);
			// var jInput = new J('<input type="text" id=$name>');
			// jInput.attr("type", "text");

			var tmp = new J("<span>");
			editor.appendTo(jForm.find("dd").last());
		}
	}

	function inputEditor(column:Column, line:Dynamic) {
		var jInput = new J("<input type='text'>");
		jInput.val(Reflect.field(line, column.name));
		jInput.change(e -> {
			Reflect.setField(line, column.name, jInput.val());
		});
		return jInput;
	}
	function selectEditor(column:Column, line:Dynamic) {
		var jSelect = new J("<select>");
		var options:Array<Dynamic> = switch (column.type) {
			case TEnum(values):
				values;
			case _:
				throw 'selectEditor cannot be used with ${column.type}';
		}
		if (column.opt) {
			var jOpt = new js.html.Option("-- null --", null, true);
			jSelect.append(jOpt);
		}
		var value:Int = Reflect.field(line, column.name);
		for (i => option in options) {
			var jOpt = new js.html.Option(option, option, false, i == value);
			jSelect.append(jOpt);
		}
		jSelect.change(e -> {
			var val = jSelect.val();
			Reflect.setField(line, column.name, options.indexOf(val));
		});
		return jSelect;
	}
	function dynamicEditor(column:Column, line:Dynamic) {
		var jInput = new J("<input type='text'>");
		jInput.val(Reflect.field(line, column.name));
		jInput.click(e -> {
			new TextEditor(
				Json.stringify(Reflect.field(line, column.name), null, "\t"),
				column.name,
				null,
				LangJson,
				(val) -> {
					jInput.val(val);
					Reflect.setField(line, column.name, sheet.base.parseDynamic(val));
				}
			);
		});
		return jInput;
	}
	// }
	// public function deleteRow(row) {
	// 	//TODO
	// }
	function getEditor(column:Column, line:Dynamic) {
		switch (column.type) {
			case TString, TId:
				return inputEditor(column, line);
			case TDynamic:
				return dynamicEditor(column, line);
			case TEnum(_):
				return selectEditor(column, line);
			case _:
				var todo = new J("<span>");
				todo[0].innerHTML = "TODO";
				return todo;
		}
	}


}
