--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Efetua trocas

if not grana then require("grana") end

grana.troca = { }

grana.troca.entrada     = grana.new{}
grana.troca.saida       = grana.new{}
grana.troca.entrada_cmd = iup.text{expand="HORIZONTAL", mask=grana.cmdmask}
grana.troca.entrada_his = iup.list{expand="YES"}
grana.troca.saida_cmd   = iup.text{expand="HORIZONTAL", mask=grana.cmdmask}
grana.troca.saida_his   = iup.list{expand="YES"}
grana.troca.saldo       = iup.label{alignment="ACENTER", expand="HORIZONTAL", font=grana.font}

grana.troca.tabs        = iup.tabs{
	iup.vbox{tabtitle="&Entrada";
		grana.troca.entrada_cmd, grana.troca.entrada.box, grana.troca.entrada_his
	},
	iup.vbox{tabtitle="&Saída";
		grana.troca.saida_cmd, grana.troca.saida.box, grana.troca.saida_his
	}
}

grana.troca.dialog      = iup.dialog{title="Troca", rastersize=grana.rastersize; startfocus=grana.troca.entrada_cmd;
	iup.vbox{margin="10x10", gap="10"; grana.troca.tabs, grana.troca.saldo}
}

function grana.troca.tabs:tabchangepos_cb(new_pos, old_pos)
	if new_pos == 0 then
		iup.SetFocus(grana.troca.entrada_cmd)
	else
		iup.SetFocus(grana.troca.saida_cmd)
	end
end

function grana.troca.saldo:update()
	local v = string.format("%f", grana.troca.entrada:total() - grana.troca.saida:total()) + 0
	if v <= -0.05 then self.fgcolor = "255 0 0"
	elseif v >= 0.05 then self.fgcolor = "0 0 255"
	else self.fgcolor = "0 255 0" end
	self.title = grana.troca.entrada:rtotal() .. " - "
		.. grana.troca.saida:rtotal() .. " = " ..
		grana.real(v)
end

function grana.troca.dialog:close_cb()
	if grana.confirmar("Abandonar troca?") == 1 then
		self:hide()
	else return iup.IGNORE end
end

function grana.troca.dialog:k_any(k)
	if k == iup.K_ESC then
		self:close_cb()
	elseif k == iup.K_l or k == iup.K_L then
		grana.troca.alvo:log_custom()
	elseif k == iup.K_F5 then
		local divergencia = ""
		if grana.troca.entrada:total() ~= grana.troca.saida:total() then
			divergencia = "ATENÇÃO!\nValores divergentes.\n"
		end
		if grana.confirmar(divergencia .. "Deseja efetuar a troca?") == 1 then
			grana.troca.alvo:trocar(grana.troca.entrada, grana.troca.saida)
			self:hide()
		end
	elseif k == iup.K_c or k == iup.K_C then
		grana.troca.tabs.valuepos = 1
		iup.SetFocus(grana.troca.saida_cmd)
		grana.troca.saida:compor(grana.troca.alvo, grana.troca.entrada:total())
		grana.troca.saldo:update()
	elseif k == iup.K_d or k == iup.K_d then
		grana.troca.tabs.valuepos = 1
		iup.SetFocus(grana.troca.saida_cmd)
		grana.troca.saida:dispor(grana.troca.alvo, grana.troca.entrada:total())
		grana.troca.saldo:update()	
	elseif k == iup.K_e or k == iup.K_E then
		grana.troca.tabs.valuepos = 0
		iup.SetFocus(grana.troca.entrada_cmd)
	elseif k == iup.K_s or k == iup.K_S then
		grana.troca.tabs.valuepos = 1
		iup.SetFocus(grana.troca.saida_cmd)
	elseif k == iup.K_CR then
		if grana.troca.tabs.valuepos == "0" then
			local comando = grana.troca.entrada:comando(grana.troca.entrada_cmd.value)
			if comando then
				grana.troca.entrada_his.insertitem1 = comando
				grana.troca.entrada_his.topitem = 1
				grana.troca.entrada_cmd.value = ""
			end
		elseif grana.troca.tabs.valuepos == "1" then
			local comando = grana.troca.saida:comando(grana.troca.saida_cmd.value)
			if comando then
				grana.troca.saida_his.insertitem1 = comando
				grana.troca.saida_his.topitem = 1
				grana.troca.saida_cmd.value = ""
			end
		end
		grana.troca.saldo:update()
	elseif k == iup.K_F1 then
		iup.Message("Ajuda",
			"ESC\tSair/Cancelar\n" ..
			"L\tRegistrar log\n" ..
			"F5\tEfetuar troca\n" ..
			"C\tCompor troco (maiores primeiro)\n" ..
			"D\tDispor troco (menores primeiro)\n" ..
			"E\tMostrar entrada\n" ..
			"S\tMostrar saída\n" ..
			"F1\tAjuda")
	end
end

function grana.troca.make(alvo)
	-- limpar tudo primeiro
	grana.troca.tabs.valuepos = 0
	grana.troca.entrada:recolher(grana.troca.entrada)
	grana.troca.saida:recolher(grana.troca.saida)
	grana.troca.saida.maximo = alvo
	grana.troca.entrada_cmd.value = ""
	grana.troca.entrada_his.removeitem = "ALL"
	grana.troca.saida_cmd.value = ""
	grana.troca.saida_his.removeitem = "ALL"
	grana.troca.saldo:update()
	-- estabelecer alvo
	grana.troca.alvo = alvo
	-- fazer
	grana.troca.dialog:popup(iup.CENTERPARENT, iup.CENTERPARENT)
end

grana.troca.parentdialog = grana.parentdialog

function grana.parentdialog(dialog)
	grana.troca.parentdialog(dialog)
	grana.troca.dialog.parentdialog = dialog
end
