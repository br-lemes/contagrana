--
-- Copyright (c) 2012,2013 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Reserva de numerário

if not grana then require("grana") end

grana.reserva = { }

grana.reserva.numerario = grana.new{}
grana.reserva.comando   = iup.text{expand="HORIZONTAL", mask=grana.cmdmask}
grana.reserva.historico = iup.list{expand="YES"}
grana.reserva.saldo     = iup.label{alignment="ACENTER", expand="HORIZONTAL", font=grana.font}
grana.reserva.dialog    = iup.dialog{title="Reserva", rastersize=grana.rastersize;
	iup.vbox{margin="10x10", gap="10";
		grana.reserva.comando,
		grana.reserva.numerario.box,
		grana.reserva.historico,
		grana.reserva.saldo
	}
}

function grana.reserva.dialog:close_cb()
	if grana.confirmar("Abandonar reserva?") == 1 then
		self:hide()
	else return iup.IGNORE end
end

function grana.reserva.dialog:k_any(k)
	if k == iup.K_ESC then
		self:close_cb()
	elseif k == iup.K_l or k == iup.K_L then
		grana.reserva.alvo:log_custom()
	elseif k == iup.K_F5 then
		if grana.confirmar("Deseja efetuar a reserva?") == 1 then
			grana.reserva.alvo:log_string("\n-- Recolhimento de reserva")
			grana.reserva.alvo:log_write()
			grana.reserva.alvo:recolher(grana.reserva.numerario)
			grana.reserva.destino:suprir(grana.reserva.numerario)
			self:hide()
		end
	elseif k == iup.K_CR then
		local comando = grana.reserva.numerario:comando(grana.reserva.comando.value)
		if comando then
			grana.reserva.historico.insertitem1 = comando
			grana.reserva.historico.topitem = 1
			grana.reserva.comando.value = ""
		end
	elseif k == iup.K_F1 then
		iup.Message("Ajuda",
			"ESC\tSair/Cancelar\n" ..
			"L\tRegistrar log\n" ..
			"F5\tEfetuar reserva\n" ..
			"F1\tAjuda")
	end
end

function grana.reserva.make(alvo, destino)
	-- limpar tudo primeiro
	grana.reserva.numerario.maximo = alvo
	grana.reserva.numerario:recolher(grana.reserva.numerario)
	grana.reserva.comando.value = ""
	grana.reserva.historico.removeitem = "ALL"
	-- estabelecer alvo
	grana.reserva.alvo = alvo
	grana.reserva.destino = destino	
	grana.reserva.saldo.title = "Saldo atual " .. alvo:rtotal()
	-- fazer
	grana.reserva.dialog:popup(iup.CENTERPARENT, iup.CENTERPARENT)
end

grana.reserva.parentdialog = grana.parentdialog

function grana.parentdialog(dialog)
	grana.reserva.parentdialog(dialog)
	grana.reserva.dialog.parentdialog = dialog
end
