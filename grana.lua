--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Módulo básico do Conta Grana

require("iuplua")

os.setlocale("C", "numeric")

grana = { }

grana.datadir = arg[1] or ""

grana.lista = {2, 5, 10, 20, 50, 100}

grana.cores = {
	[2]   = "217 235 249",
	[5]   = "229 221 234",
	[10]  = "242 208 199",
	[20]  = "249 239 204",
	[50]  = "247 231 198",
	[100] = "209 234 241",
}

grana.size = "HALFxHALF"

grana.font = "HELVETICA_BOLD_12"

grana.cmdmask = "[/*/-]?=(/d+,?/d*|,/d+)|/d+[/*//]/d*|/*/d*|-/d+[/*//]/d*"

grana.method = { }
grana.metatable = { }
grana.metatable.__index = grana.method

-- converte em notação de reais
function grana.real(valor)
	valor = string.format("%f", valor) + 0
	valor = string.gsub(string.format("%.2f", valor), "%.", ",")
	while true do
		valor, k = valor:gsub("^(-?%d+)(%d%d%d)", '%1.%2')
		if (k == 0) then break end
	end
	return "R$ " .. valor
end

-- cria uma vbox
function grana.criar_box()
	function frame(nota)
		local f = iup.frame{iup.label{expand="HORIZONTAL", alignment="ACENTER", font=grana.font, tipdelay="32767"}}
		if nota then f.bgcolor = grana.cores[nota] end
		return f
	end
	local box = iup.vbox{margin="0x0", gap="10";
		iup.hbox{homogeneous="YES", margin="0x0"; frame(2), frame(5), frame(10)},
		iup.hbox{homogeneous="YES", margin="0x0"; frame(20), frame(50), frame(100)},
		iup.hbox{homogeneous="YES", margin="0x0"; frame(), frame(), frame()}
	}
	return box
end

-- contar moedas em reais
function grana.method:rmoedas()
	return grana.real(self.moedas)
end

-- contar as notas
function grana.method:notas(nota)
	if nota then
		return self[nota] * nota
	else
		local total = 0
		for i,v in ipairs(grana.lista) do
			total = total + self[v] * v
		end
		return total
	end
end

-- contar as notas em reais
function grana.method:rnotas(nota)
	return grana.real(self:notas(nota))
end

-- total de notas + moedas
function grana.method:total()
	return self:notas() + self.moedas
end

-- total de notas + moedas em reais
function grana.method:rtotal()
	return grana.real(self:total())
end

-- executa comandos, adicionando ou removendo notas/moedas
-- retorna uma string com a descrição do comando ou nil se inválido
function grana.method:comando(cmd)
	cmd = cmd:gsub(",", ".")
	-- comando limpar
	if cmd == "-" then
		valor = self:total() * -1
		for i,v in ipairs(grana.lista) do
			self[v] = 0
		end
		self.moedas = 0
		self:box_update()
		return "- = " .. grana.real(valor)
	end
	-- comando limpar em moedas
	if cmd:sub(1, 2) == "-=" then
		if #cmd == 2 then
			local valor = self.moedas * -1
			self.moedas = 0
			self:box_update()
			return "-= " .. grana.real(valor)
		else
			local valor = tonumber(cmd:sub(3))
			if not valor then return nil end -- formato inválido
			if valor > self.moedas then return nil end -- valor inválido
			self.moedas = self.moedas - valor
			self:box_update()
			return cmd .. " = " .. grana.real(valor * -1)
		end
	end
	-- comando limpar em notas
	if cmd:sub(1, 1) == "-" then
		local nota, quantidade
		local i = cmd:find("*")
		if not i then
			local k = cmd:find("/")
			if k then -- valor em notas (divisão)
				nota = tonumber(cmd:sub(k+1))
				quantidade = tonumber(cmd:sub(2, k-1))
				if quantidade then
					local resto
					quantidade, resto = math.modf(quantidade / nota)
					if resto > 0 then return nil end -- quantidade inválida
				end
			else -- uma nota
				nota = tonumber(cmd:sub(2))
				quantidade = 1
			end
		elseif i == 2 then -- todas as notas
			nota = tonumber(cmd:sub(3))
			quantidade = self[nota]
		else -- quantidade específica de notas
			nota = tonumber(cmd:sub(i+1))
			quantidade = tonumber(cmd:sub(2, i-1))
		end
		if not nota then return nil end -- formato inválido
		if not quantidade then return nil end -- formato inválido
		if not self[nota] then return nil end -- nota inválida
		if quantidade > self[nota] then return nil end -- quantidade inválida
		self[nota] = self[nota] - quantidade
		self:box_update()
		return cmd .. " = " .. grana.real(quantidade * nota)
	end
	-- comando máximo
	if cmd == "*" then
		if self.maximo then
			for i,v in ipairs(grana.lista) do
				self[v] = self.maximo[v]
			end
			self.moedas = self.maximo.moedas
			self:box_update()
			return "* = " .. self:rtotal()
		else return nil end -- sem máximo definido
	end
	-- comando máximo em moedas
	if cmd == "*=" then
		if self.maximo then
			self.moedas = self.maximo.moedas
			self:box_update()
			return "*= = " .. self:rmoedas()
		else return nil end -- sem máximo definido
	end
	-- comando máximo em uma nota
	if cmd:sub(1, 1) == "*" then
		if self.maximo then
			local nota = tonumber(cmd:sub(2))
			if not nota then return nil end -- formato inválido
			if not self[nota] then return nil end -- nota inválida
			self[nota] = self.maximo[nota]
			self:box_update()
			return cmd .. " = " .. self:rnotas(nota)
		else return nil end -- sem máximo definido
	end
	-- comando moedas
	if cmd:sub(1, 1) == "=" then
		local valor = tonumber(cmd:sub(2))
		if not valor then return nil end -- formato inválido
		if self.maximo and self.moedas + valor > self.maximo.moedas then
			return nil -- não ultrapasse o limite
		end
		self.moedas = self.moedas + valor
		self:box_update()
		return cmd .. " = " .. grana.real(valor)
	end
	-- comando notas
	local quantidade, nota
	local i = cmd:find("*")
	if not i then
		local k = cmd:find("/")
		if k then -- valor em notas (divisão)
			nota = tonumber(cmd:sub(k+1))
			quantidade = tonumber(cmd:sub(1, k-1))
			if quantidade then
				local resto
				quantidade, resto = math.modf(quantidade / nota)
				if resto > 0 then return nil end -- quantidade inválida
			end
		else -- uma nota
			quantidade = 1
			nota = tonumber(cmd)
		end
	else -- quantidade específica de notas
		quantidade = tonumber(cmd:sub(1, i-1))
		nota = tonumber(cmd:sub(i+1))
	end
	if not nota then return nil end -- formato inválido
	if not quantidade then return nil end -- formato inválido
	if not self[nota] then return nil end -- nota inválida
	if self.maximo and self[nota] + quantidade > self.maximo[nota] then
		return nil -- não ultrapasse o limite
	end
	self[nota] = self[nota] + quantidade
	self:box_update()
	return cmd .. " = " .. grana.real(nota * quantidade)
end

-- salva dados em um arquivo
function grana.method:salvar()
	local str = "\nGrana" .. self:long_string(tostring(self.arquivo))
	if not self.arquivo then
		if grana.debug then
			if grana.key then
				io.stdout:write(md5.crypt(str, grana.key))
			else
				io.stdout:write(str)
			end
		end
	else
		local arquivo = io.open(grana.datadir .. self.arquivo .. ".grana", "wb")
		if grana.key then
			arquivo:write(md5.crypt(str, grana.key))
		else
			arquivo:write(str)
		end
		arquivo:close()
	end
end

-- grava log em um arquivo
function grana.method:log_write()
	if not self.arquivo then
		if grana.debug then
			if grana.key then
				io.stdout:write("\nConta Grana Log\n")
				io.stdout:write(md5.crypt(self.log_msg, grana.key))
			else
				io.stdout:write(self.log_msg)
			end
		end
	else
		local arquivo = io.open(grana.datadir .. self.arquivo .. "-" .. os.date("%F") .. ".log", "ab")
		if grana.key then
			arquivo:write("\nConta Grana Log\n")
			arquivo:write(md5.crypt(self.log_msg, grana.key))
		else
			arquivo:write(self.log_msg)
		end
		arquivo:close()
	end
	self.log_msg = ""
end

-- gera cabeçalho de log
function grana.method:log_head(head)
	self.log_msg = self.log_msg .. "\n" .. head .. "{\n\tdata        = " .. 
		string.format("%q", os.date("%d/%m/%y %H:%M:%S")) .. ",\n"
end

-- gera mensagem de log
function grana.method:log_string(str)
	self.log_msg = self.log_msg .. tostring(str) .. "\n"
end

-- gera dados de log
function grana.method:log_data(name, data)
	self.log_msg = self.log_msg .. 
		"\t" .. "v_" .. name .. string.rep(" ", 10-#name) .. "= " .. data:total() .. ",\n" ..
		"\t" .. "n_" .. name .. string.rep(" ", 10-#name) .. "= " .. data:short_string() .. ",\n"
end

-- grava log personalizado
function grana.method:log_custom()
	local ok, str = iup.GetParam("Registrar Log", nil, "%s\n", "")
	if ok then
		self:log_string("\n-- " .. os.date("%d/%m/%y %H:%M:%S") .. " - " .. str)
		self:log_write()
	end
end

-- retorna string curta com os dados monetários
function grana.method:short_string()
	local s = "{"
	for i,v in ipairs(grana.lista) do
		s = s .. "[" .. v .. "]=" .. self[v] .. ","
	end
	return s .. "moedas=" .. tostring(self.moedas) .. "}"
end

-- retorna string longa com os dados monetários
function grana.method:long_string(arquivo)
	local s = "{\n"
	local m = math.floor(self.moedas)
	for i,v in ipairs(grana.lista) do
		m = math.max(m, self[v])
	end
	for i,v in ipairs(grana.lista) do
		s = s .. "\t[" .. v .. "]" .. string.rep(" ", 6 - #tostring(v)) .. "=" .. string.rep(" ", #tostring(m) + 1 - #tostring(self[v])) .. self[v] .. ",\n"
	end
	s = s .. "\tmoedas  =" .. string.rep(" ", #tostring(m) + 1 - #tostring(math.floor(self.moedas))) .. tostring(self.moedas)
	if arquivo then
		s = s .. ",\n\tarquivo = " .. string.format("%q", arquivo)
	end
	return s .. "\n}"
end

-- realiza suprimento de numerário
-- sempre retorna true
function grana.method:suprir(numerario)
	self:log_head("Suprimento")
	self:log_data("anterior", self)
	self:log_data("suprido", numerario)
	for i,k in ipairs(grana.lista) do
		self[k] = self[k] + numerario[k]
	end
	self.moedas = self.moedas + numerario.moedas
	self:log_data("atual", self)
	self:log_string("}")
	self:log_write()
	self:salvar()
	self:box_update()
	return true
end

-- realiza recolhimento de numerário
-- retorna true ou nil se o recolhimento for inválido
function grana.method:recolher(numerario)
	self:log_head("Recolhimento")
	self:log_data("anterior", self)
	self:log_data("recolhido", numerario)
	for i,k in ipairs(grana.lista) do
		if self[k] - numerario[k] < 0 then
			self:log_string("** INVÁLIDO **")
			self:log_write()
			return nil
		end
	end
	if self.moedas - numerario.moedas < 0 then
		self:log_string("** INVÁLIDO **")
		self:log_write()
		return nil
	end
	for i,k in ipairs(grana.lista) do
		self[k] = self[k] - numerario[k]
	end
	self.moedas = self.moedas - numerario.moedas
	self:log_data("atual", self)
	self:log_string("}")
	self:log_write()
	self:salvar()
	self:box_update()
	return true
end

-- realiza troca de numerario
-- CUIDADO: a troca pode ser divergente, confira primeiro
-- retorna true ou nil se a troca for inválida
function grana.method:trocar(entrada, saida)
	self:log_head("Troca")
	self:log_string("\tdivergencia = " .. entrada:total() - saida:total() .. ",")
	self:log_data("anterior", self)
	self:log_data("entrada", entrada)
	self:log_data("saida", saida)
	for i,k in ipairs(grana.lista) do
		if self[k] < saida[k] then
			self:log_string("** INVÁLIDO **")
			self:log_write()
			return nil
		end
	end
	if self.moedas < saida.moedas then
		self:log_string("** INVÁLIDO **")
		self:log_write()
		return nil
	end
	for i,k in ipairs(grana.lista) do
		self[k] = self[k] + entrada[k]
		self[k] = self[k] - saida[k]
	end
	self.moedas = self.moedas + entrada.moedas
	self.moedas = self.moedas - saida.moedas
	self:log_data("atual", self)
	self:log_string("}")
	self:log_write()
	self:salvar()
	self:box_update()
	return true
end

-- realiza um pagamento
-- CUIDADO: o troco pode ser divergente, confira primeiro
-- retorna true ou nil se o pagamento for inválido
function grana.method:pagar(valor, entrada, saida)
	self:log_head("Pagamento")
	self:log_string("\tdivergencia = " .. (string.format("%f", valor - entrada:total() + saida:total()) + 0) * -1 .. ",")
	self:log_string("\tv_receber   = " .. valor .. ",")
	self:log_data("anterior", self)
	self:log_data("entrada", entrada)
	self:log_data("saida", saida)
	for i,k in ipairs(grana.lista) do
		if self[k] < saida[k] then
			self:log_string("** INVÁLIDO **")
			self:log_write()
			return nil
		end
	end
	if self.moedas < saida.moedas then
		self:log_string("** INVÁLIDO **")
		self:log_write()
		return nil
	end
	for i,k in ipairs(grana.lista) do
		self[k] = self[k] + entrada[k]
		self[k] = self[k] - saida[k]
	end
	self.moedas = self.moedas + entrada.moedas
	self.moedas = self.moedas - saida.moedas
	self:log_data("atual", self)
	self:log_string("}")
	self:log_write()
	self:salvar()
	self:box_update()
	return true
end

-- atualiza dados da box
function grana.method:box_update(maximo)
	function update(label, nota)
		label.title = self[nota] .. " * " .. nota .. " Reais \n" .. self:rnotas(nota)
		if self[nota] == 0 then
			label.fgcolor = grana.cores[nota]
			label.tip = ""
		else
			if maximo then
				if self[nota] > maximo[nota] then
					label.fgcolor = "0 0 255"
					label.tip = self[nota] - maximo[nota] .. " notas excedentes"
				else
					label.tip = ""
				end
			else
				label.fgcolor = "0 0 0"
			end
		end
	end
	
	update(self.box[1][1][1],   2)
	update(self.box[1][2][1],   5)
	update(self.box[1][3][1],  10)
	update(self.box[2][1][1],  20)
	update(self.box[2][2][1],  50)
	update(self.box[2][3][1], 100)
	self.box[3][1][1].title  = "Notas " .. self:rnotas()
	self.box[3][2][1].title = "Moedas " .. self:rmoedas()
	self.box[3][3][1].title  = "Total " .. self:rtotal()
end

-- compõe troco a partir de um numerário disponível e um valor
-- geralmente notas maiores primeiro
function grana.method:compor(numerario, valor)
	valor = valor - self:total()

	function dnotas(nota, minimo, maximo)
		if valor > 1 and numerario[nota] > minimo then
			local n = math.modf(valor / nota)
			if self[nota] + n > numerario[nota] - minimo then
				n = numerario[nota] - self[nota] - minimo
			end
			if maximo and n > maximo then n = maximo end
			valor = valor - nota * n
			self[nota] = self[nota] + n
		end
	end

	dnotas(20, 25, 5)
	if valor < 100 then dnotas(10, 25, 5) end
	if numerario[100] < 5 and numerario[50] > 10 then
		dnotas(50, 0)
	end
	dnotas(100, 0)
	dnotas( 50, 0)
	dnotas( 20, 0)
	dnotas( 10, 0)
	dnotas(  5, 0)
	dnotas(  2, 0)
	self:box_update()
end

-- compõe troco a partir de um numerário disponível e um valor
-- geralmente notas menores primeiro
function grana.method:dispor(numerario, valor)
	valor = valor - self:total()

	function dnotas(nota, minimo)
		if valor > 1 and numerario[nota] > minimo then
			local n = math.modf(valor / nota)
			if self[nota] + n > numerario[nota] - minimo then
				n = numerario[nota] - self[nota] - minimo
			end
			valor = valor - nota * n
			self[nota] = self[nota] + n
		end
	end

	dnotas(  5, 10)
	dnotas( 10,  5)
	dnotas( 20,  3)
	dnotas( 50,  0)
	dnotas(100,  0)
	dnotas( 20,  0)
	dnotas( 10,  0)
	dnotas(  5,  0)
	dnotas(  2,  0)
	self:box_update()
end

-- cria uma nova instância do objeto
function grana.new(new)
	new.log_msg      = ""
	new[2]           = new[2]     or 0
	new[5]           = new[5]     or 0
	new[10]          = new[10]    or 0
	new[20]          = new[20]    or 0
	new[50]          = new[50]    or 0
	new[100]         = new[100]   or 0
	new.moedas       = new.moedas or 0
	new.box          = grana.criar_box()
	setmetatable(new, grana.metatable)
	new:box_update()
	return new
end

-- cria uma nova instância do objeto carregando dados de um arquivo, se o
-- arquivo não existir, cria uma nova instância vazia no ambiente global
function grana.carregar(arquivo)
	if not arquivo then error("nil value") end
	local i
	if grana.key then
		local file = io.open(grana.datadir .. arquivo .. ".grana", "rb")
		if file then
			local chunk = md5.decrypt(file:read("*a"), grana.key)
			file:close()
			local func = loadstring(chunk, arquivo)
			i = pcall(func)
		end
	else
		i = pcall(dofile, grana.datadir .. arquivo .. ".grana")
	end
	if not i then _G[arquivo] = grana.new{arquivo=arquivo} end
end

function grana.parentdialog(dialog)
end

function grana.confirmar(message)
	local dlg = iup.messagedlg{
		title="Confirmar",
		value=message,
		buttons="YESNO",
		dialogtype="QUESTION"
	}
	dlg:popup()
	return tonumber(dlg.buttonresponse)
end

function Grana(valores)
	if not _G[valores.arquivo] then
		_G[valores.arquivo] = grana.new(valores)
	else
		_G[valores.arquivo][2] = valores[2] or _G[valores.arquivo][2]
		_G[valores.arquivo][5] = valores[5] or _G[valores.arquivo][5]
		_G[valores.arquivo][10] = valores[10] or _G[valores.arquivo][10]
		_G[valores.arquivo][20] = valores[20] or _G[valores.arquivo][20]
		_G[valores.arquivo][50] = valores[50] or _G[valores.arquivo][50]
		_G[valores.arquivo][100] = valores[100] or _G[valores.arquivo][100]
		_G[valores.arquivo].moedas = valores.moedas or _G[valores.arquivo].moedas
		_G[valores.arquivo].arquivo = valores.arquivo or _G[valores.arquivo].arquivo
	end
end

require("logreader")
require("suprimento")
require("recolhimento")
