--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Efetua pagamentos

if not grana then require("grana") end

grana.pagamento = { }

grana.pagamento.entrada     = grana.new{}
grana.pagamento.saida       = grana.new{}
grana.pagamento.entrada_cmd = iup.text{expand="HORIZONTAL", mask=grana.cmdmask}
grana.pagamento.entrada_his = iup.list{expand="YES"}
grana.pagamento.saida_cmd   = iup.text{expand="HORIZONTAL", mask=grana.cmdmask}
grana.pagamento.saida_his   = iup.list{expand="YES"}
grana.pagamento.saldo       = iup.label{alignment="ACENTER", expand="HORIZONTAL", font=grana.font}

function grana.pagamento.saldo:update()
	local v = string.format("%f", grana.pagamento.receber - grana.pagamento.entrada:total() + grana.pagamento.saida:total()) + 0
	if v >= 0.05 then self.fgcolor = "255 0 0"
	elseif v <= -0.05 then self.fgcolor = "0 0 255"
	else self.fgcolor = "0 255 0" end
	self.title = grana.real(grana.pagamento.receber) .. " - " ..
		grana.pagamento.entrada:rtotal() .. " + " ..
		grana.pagamento.saida:rtotal() .. " = " ..
		grana.real(v)
end

grana.pagamento.tabs = iup.tabs{iup.vbox{
	tabtitle="&Entrada";
		grana.pagamento.entrada_cmd, grana.pagamento.entrada.box, grana.pagamento.entrada_his
	},
	iup.vbox{tabtitle="&Saída";
		grana.pagamento.saida_cmd, grana.pagamento.saida.box, grana.pagamento.saida_his
	}
}

grana.pagamento.dialog = iup.dialog{title="Pagamento", rastersize=grana.rastersize;
	iup.vbox{margin="10x10", gap="10"; grana.pagamento.tabs, grana.pagamento.saldo}
}

function grana.pagamento.tabs:tabchangepos_cb(new_pos, old_pos)
	if new_pos == 0 then
		iup.SetFocus(grana.pagamento.entrada_cmd)
	else
		iup.SetFocus(grana.pagamento.saida_cmd)
	end
end

function grana.pagamento.dialog:close_cb()
	if grana.confirmar("Abandonar pagamento?") == 1 then
		self:hide()
	else return iup.IGNORE end
end

function grana.pagamento.dialog:k_any(k)
	if k == iup.K_ESC then
		self:close_cb()
	elseif k == iup.K_l or k == iup.K_L then
		grana.pagamento.alvo:log_custom()
	elseif k == iup.K_F5 then
		local divergencia = ""
		if string.format("%f", grana.pagamento.receber - grana.pagamento.entrada:total() + grana.pagamento.saida:total()) + 0 ~= 0 then
			divergencia = "ATENÇÃO!\nValores divergentes.\n"
		end
		if grana.confirmar(divergencia .. "Deseja efetuar o pagamento?") == 1 then
			grana.pagamento.alvo:pagar(grana.pagamento.receber, grana.pagamento.entrada, grana.pagamento.saida)
			grana.pagamento.retorno = true
			self:hide()
		end
	elseif k == iup.K_c or k == iup.K_C then
		grana.pagamento.tabs.valuepos = 1
		iup.SetFocus(grana.pagamento.saida_cmd)
		grana.pagamento.saida:compor(grana.pagamento.alvo, (grana.pagamento.receber - grana.pagamento.entrada:total()) * -1)
		grana.pagamento.saldo:update()
	elseif k == iup.K_d or k == iup.K_D then
		grana.pagamento.tabs.valuepos = 1
		iup.SetFocus(grana.pagamento.saida_cmd)
		grana.pagamento.saida:dispor(grana.pagamento.alvo, (grana.pagamento.receber - grana.pagamento.entrada:total()) * -1)
		grana.pagamento.saldo:update()
	elseif k == iup.K_e or k == iup.K_E then
		grana.pagamento.tabs.valuepos = 0
		iup.SetFocus(grana.pagamento.entrada_cmd)
	elseif k == iup.K_s or k == iup.K_S then
		grana.pagamento.tabs.valuepos = 1
		iup.SetFocus(grana.pagamento.saida_cmd)
	elseif k == iup.K_n or k == iup.K_N then
		if grana.notas then
			grana.pagamento.tabs.valuepos = 0
			iup.SetFocus(grana.pagamento.entrada_cmd)
			if grana.pagamento.entrada:total() == 0 then
				grana.pagamento.entrada:suprir(grana.notas.numerario)
				grana.pagamento.saldo:update()
			end
		end
	elseif k == iup.K_CR then
		if grana.pagamento.tabs.valuepos == "0" then
			local comando = grana.pagamento.entrada:comando(grana.pagamento.entrada_cmd.value)
			if comando then
				grana.pagamento.entrada_his.insertitem1 = comando
				grana.pagamento.entrada_his.topitem = 1
				grana.pagamento.entrada_cmd.value = ""
			end
		elseif grana.pagamento.tabs.valuepos == "1" then
			local comando = grana.pagamento.saida:comando(grana.pagamento.saida_cmd.value)
			if comando then
				grana.pagamento.saida_his.insertitem1 = comando
				grana.pagamento.saida_his.topitem = 1
				grana.pagamento.saida_cmd.value = ""
			end
		end
		grana.pagamento.saldo:update()
	elseif k == iup.K_F1 then
		iup.Message("Ajuda",
			"ESC\tSair/Cancelar\n" ..
			"L\tRegistrar log\n" ..
			"F5\tEfetuar pagamento\n" ..
			"C\tCompor troco (maiores primeiro)\n" ..
			"D\tDispor troco (menores primeiro)\n" ..
			"E\tMostrar entrada\n" ..
			"S\tMostrar saída\n" ..
			"N\tÚltima contagem de notas\n" ..
			"F1\tAjuda")
	end
end

function grana.pagamento.dialog:show_cb()
	if grana.pagamento.receber > 0 then
		grana.pagamento.tabs.valuepos = 0
		iup.SetFocus(grana.pagamento.entrada_cmd)
	else
		grana.pagamento.tabs.valuepos = 1
		iup.SetFocus(grana.pagamento.saida_cmd)
	end
end

function grana.pagamento.make(receber, alvo)
	-- limpar tudo primeiro
	grana.pagamento.retorno = nil
	grana.pagamento.receber = receber
	grana.pagamento.tabs.valuepos = 0
	grana.pagamento.entrada:recolher(grana.pagamento.entrada)
	grana.pagamento.saida:recolher(grana.pagamento.saida)
	grana.pagamento.saida.maximo = alvo
	grana.pagamento.entrada_cmd.value = ""
	grana.pagamento.entrada_his.removeitem = "ALL"
	grana.pagamento.saida_cmd.value = ""
	grana.pagamento.saida_his.removeitem = "ALL"
	grana.pagamento.saldo:update()
	-- estabelecer alvo
	grana.pagamento.alvo = alvo
	-- fazer
	grana.pagamento.dialog:popup(iup.CENTERPARENT, iup.CENTERPARENT)
	return grana.pagamento.retorno
end

grana.pagamento.parentdialog = grana.parentdialog

function grana.parentdialog(dialog)
	grana.pagamento.parentdialog(dialog)
	grana.pagamento.dialog.parentdialog = dialog
end
