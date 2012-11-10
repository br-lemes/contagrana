--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Contar notas

if not grana then require("grana") end

grana.notas = { }

grana.notas.numerario = grana.new{}
grana.notas.comando   = iup.text{expand="HORIZONTAL", mask=grana.cmdmask}
grana.notas.historico = iup.list{expand="YES"}
grana.notas.saldo     = iup.label{alignment="ACENTER", expand="HORIZONTAL", font=grana.font}
grana.notas.dialog    = iup.dialog{title="Notas", size=grana.size;
	iup.vbox{margin="10x10", gap="10";
		grana.notas.comando,
		grana.notas.numerario.box,
		grana.notas.historico,
		grana.notas.saldo
	}
}

function grana.notas.dialog:close_cb()
	if grana.confirmar("Abandonar notas?") == 1 then
		self:hide()
	else return iup.IGNORE end
end

function grana.notas.dialog:k_any(k)
	if k == iup.K_ESC or k == iup.K_F5 then
		self:close_cb()
	elseif k == iup.K_l or k == iup.K_L then
		grana.notas.alvo:log_custom()
	elseif k == iup.K_CR then
		local comando = grana.notas.numerario:comando(grana.notas.comando.value)
		if comando then
			grana.notas.historico.insertitem1 = comando
			grana.notas.historico.topitem = 1
			grana.notas.comando.value = ""
		end
	elseif k == iup.K_F1 then
		iup.Message("Ajuda",
			"ESC\tSair\n" ..
			"L\tRegistrar log\n" ..
			"F1\tAjuda")
	end
end

function grana.notas.make()
	grana.notas.numerario:recolher(grana.notas.numerario)
	grana.notas.comando.value = ""
	grana.notas.historico.removeitem = "ALL"
	grana.notas.dialog:popup(iup.CENTERPARENT, iup.CENTERPARENT)
	return grana.notas.numerario:total()
end

grana.notas.parentdialog = grana.parentdialog

function grana.parentdialog(dialog)
	grana.notas.parentdialog(dialog)
	grana.notas.dialog.parentdialog = dialog
end
