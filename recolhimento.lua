--
-- Copyright (c) 2012,2013 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Recolhimento de numerário

if not grana then require("grana") end

grana.recolhimento = { }

grana.recolhimento.numerario = grana.new{}
grana.recolhimento.comando   = iup.text{expand="HORIZONTAL", mask=grana.cmdmask}
grana.recolhimento.historico = iup.list{expand="YES"}
grana.recolhimento.saldo     = iup.label{alignment="ACENTER", expand="HORIZONTAL", font=grana.font}
grana.recolhimento.dialog    = iup.dialog{title="Recolhimento", rastersize=grana.rastersize;
	iup.vbox{margin="10x10", gap="10";
		grana.recolhimento.comando,
		grana.recolhimento.numerario.box,
		grana.recolhimento.historico,
		grana.recolhimento.saldo
	}
}

function grana.recolhimento.dialog:close_cb()
	if grana.confirmar("Abandonar recolhimento?") == 1 then
		self:hide()
	else return iup.IGNORE end
end

function grana.recolhimento.dialog:k_any(k)
	if k == iup.K_ESC then
		self:close_cb()
	elseif k == iup.K_l or k == iup.K_L then
		grana.recolhimento.alvo:log_custom()
	elseif k == iup.K_F5 then
		if grana.confirmar("Deseja efetuar o recolhimento?") == 1 then
			grana.recolhimento.alvo:recolher(grana.recolhimento.numerario)
			self:hide()
		end
	elseif k == iup.K_CR then
		local comando = grana.recolhimento.numerario:comando(grana.recolhimento.comando.value)
		if comando then
			grana.recolhimento.historico.insertitem1 = comando
			grana.recolhimento.historico.topitem = 1
			grana.recolhimento.comando.value = ""
		end
	elseif k == iup.K_F1 then
		iup.Message("Ajuda",
			"ESC\tSair/Cancelar\n" ..
			"L\tRegistrar log\n" ..
			"F5\tEfetuar recolhimento\n" ..
			"F1\tAjuda")
	end
end

function grana.recolhimento.make(alvo)
	-- limpar tudo primeiro
	grana.recolhimento.numerario.maximo = alvo
	grana.recolhimento.numerario:recolher(grana.recolhimento.numerario)
	grana.recolhimento.comando.value = ""
	grana.recolhimento.historico.removeitem = "ALL"
	-- estabelecer alvo
	grana.recolhimento.alvo = alvo
	grana.recolhimento.saldo.title = "Saldo atual " .. alvo:rtotal()
	-- fazer
	grana.recolhimento.dialog:popup(iup.CENTERPARENT, iup.CENTERPARENT)
end

grana.recolhimento.parentdialog = grana.parentdialog

function grana.parentdialog(dialog)
	grana.recolhimento.parentdialog(dialog)
	grana.recolhimento.dialog.parentdialog = dialog
end
