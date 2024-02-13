package ui.modal.dialog;

import haxe.DynamicAccess;
import cdb.Sheet;


class SheetOverride extends ui.modal.Dialog {
	var onConfirm : Null<Dynamic->Void>;
	var sheet : Sheet;
	var line : Dynamic;
	var originalLine : Dynamic;

	public function new(sheet: Sheet, line:Dynamic, originalLine:Dynamic, ?onConfirm:Dynamic->Void) {
        super();
		this.onConfirm = onConfirm;
		this.sheet = sheet;
		this.originalLine = originalLine;
		this.line = merge(originalLine, line);

        var sheetDefsForm = new ui.SheetDefsForm(sheet, this.line);
        jContent.append(sheetDefsForm.jWrapper);
		
		addConfirm(() -> if (onConfirm != null) onConfirm(getDiff()));
    }
	function merge(base: Dynamic, ext: Dynamic) {
        var res = Reflect.copy(base);
        for(f in Reflect.fields(ext)) {
			Reflect.setField(res, f, Reflect.field(ext, f));
		}
        return res;
  }
	function getDiff() {
		var l: DynamicAccess<Dynamic> = {};
		for (k in Reflect.fields(line)) {
			var newValue = Reflect.field(line, k);
			if (Reflect.field(originalLine, k) != Reflect.field(line, k)) {
				l.set(k, newValue);
			}
		}
		return l.keys().length > 0 ? l : null;
	}
}