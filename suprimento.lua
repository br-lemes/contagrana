--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Suprimento de numerário

if not grana then require("grana") end

grana.suprimento = { }

grana.suprimento.numerario = grana.new{}
grana.suprimento.comando   = iup.text{expand="HORIZONTAL", mask=grana.cmdmask}
grana.suprimento.historico = iup.list{expand="YES"}
grana.suprimento.saldo     = iup.label{alignment="ACENTER", expand="HORIZONTAL", font=grana.font}
grana.suprimento.dialog    = iup.dialog{title="Suprimento", rastersize=grana.rastersize;
	iup.vbox{margin="10x10", gap="10";
		grana.suprimento.comando,
		grana.suprimento.numerario.box,
		grana.suprimento.historico,
		grana.suprimento.saldo
	}
}

function grana.suprimento.dialog:close_cb()
	if grana.confirmar("Abandonar suprimento?") == 1 then
		self:hide()
	else return iup.IGNORE end
end

function grana.suprimento.dialog:k_any(k)
	if k == iup.K_ESC then
		self:close_cb()
	elseif k == iup.K_l or k == iup.K_L then
		grana.suprimento.alvo:log_custom()
	elseif k == iup.K_F5 then
		if grana.confirmar("Deseja efetuar o suprimento?") == 1 then
			if grana.suprimento.reserva then
				caixa:log_string("\n-- Suprimento de reserva")
				caixa:log_write()
				grana.suprimento.reserva:recolher(grana.suprimento.numerario)
			end
			grana.suprimento.alvo:suprir(grana.suprimento.numerario)
		end
		self:hide()
	elseif k == iup.K_CR then
		local comando = grana.suprimento.numerario:comando(grana.suprimento.comando.value)
		if comando then
			grana.suprimento.historico.insertitem1 = comando
			grana.suprimento.historico.topitem = 1
			grana.suprimento.comando.value = ""
		end
	elseif k == iup.K_F1 then
		iup.Message("Ajuda",
			"ESC\tSair/Cancelar\n" ..
			"L\tRegistrar log\n" ..
			"F5\tEfetuar suprimento\n" ..
			"F1\tAjuda")
	end
end

function grana.suprimento.make(alvo, reserva)
	-- limpar tudo primeiro
	grana.suprimento.reserva = reserva
	grana.suprimento.numerario:recolher(grana.suprimento.numerario)
	grana.suprimento.numerario.maximo = reserva
	grana.suprimento.comando.value = ""
	grana.suprimento.historico.removeitem = "ALL"
	-- estabelecer alvo
	grana.suprimento.alvo = alvo
	grana.suprimento.saldo.title = "Saldo atual " .. alvo:rtotal()
	-- fazer
	grana.suprimento.dialog:popup(iup.CENTERPARENT, iup.CENTERPARENT)
end

grana.suprimento.parentdialog = grana.parentdialog

function grana.parentdialog(dialog)
	grana.suprimento.parentdialog(dialog)
	grana.suprimento.dialog.parentdialog = dialog
end
