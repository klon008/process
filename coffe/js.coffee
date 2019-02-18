if !(window.File and window.FileReader and window.FileList and window.Blob)
  alert 'Браузер не поддерживает чтение файлов!!!!'
##Реализация системы разделения времени
class mConsole
  @t = document.getElementById('console')
  @log: (inText)->
    if (typeof inText is 'string')
      mConsole.t.innerHTML += "<div>#{inText}</div>"
    else throw inText + " не является текстом"
tippy(".spooling_element")
#Приоритеты процессов
###################################

process_priors = Object.freeze({
  Highest: "Очень высокий" #Очень высокий
  High: "Высокий"    #Высокий
  Normal: "Нормальный"  #Нормальный
  Low: "Низкий"     #Низкий
  Lowest: "Очень низкий"  #Очень низкий
})
process_states = Object.freeze({
  None: "Нет состояния", #Нет состояния
  Run: "Выполнение", #Выполнение
  Ready: "Готовность", #Готовность
  Wait: "Ожидание", #Ожидание
  Finish: "Завершился"
})
TStateProcessor = Object.freeze({
  Empty: "Empty",
  Busy: "Busy"
})
process_comands = Object.freeze({
  NONE: "NONE",
  MEMORY: "ПАМЯТЬ", #Память
  PROCESSOR: "ПРОЦЕССОР", #Процессор
  IO: "ВВОД\\ВЫВОД"  #Input/Output
  end: "КОНЕЦ"
})
img_cats = [
  "1.jfif", "2.jpg", "3.jfif", "4.jfif", "5.png", "6.png", "7.jfif", "8.png"
]

ready_processes_stack = []
waiting_processes_stack = []
all_processes_stack = []
#ПАМЯТЬ!
class mMemoryCell
  constructor: (@busy = false           #Флаг занятости
    @pid = null              #Пид ячейки памяти
    @name = null             #Имя процесса занявшего ячейку памяти
    @memory = null           #параметр занятой памяти (используется для визуального отображения
    @htmlLinks = null        #ссылка на DOM
    @process = null
    @start_byte = null
    @end_byte = null)->
    return @
  draw_mem: ()->
    memoryTable = document.querySelector("#memory_table")
    tr = document.createElement "div"

    tr.setAttribute('data-id', @pid)
    tr.setAttribute('data-mem_used', @memory)
    tr.innerHTML = "<b>#{@pid}</b>"
    tr.classList.add("blocked")
    tr.style.width = 100 * @memory / mMemory.MAX + "%";
    tr.style.left = 100 * @start_byte / mMemory.MAX + "%";
    memoryTable.append(tr)
    @htmlLinks = tr

class mMemory
  @FREE: 65535
  @MAX: 65535
  @memory_sections: []
  @use: (process, mem) ->
    if @FREE > mem #проверяем что свободной памяти хватает ( но это не точно )
      if true      #проверяем есть остались ли свободные пространства между занятыми ячейками
        cell = new mMemoryCell(true, process.descriptor.pid, process.descriptor.FileName, mem, null, process, null, null)
        if @memory_sections.length == 0
          cell.start_byte = 0
          cell.end_byte = cell.start_byte + mem
          do cell.draw_mem
          @FREE = @FREE - cell.memory
          @memory_sections.push(cell)
          process.context.memory = mem
          mConsole.log "Процесс <span class='proc_name'>#{process.descriptor.FileName}</span>
<b>(#{process.descriptor.pid})</b> Занял <b>#{cell.memory}</b> Памяти!"
        else
          i_mem = 0
          while i_mem <= @MAX
            busy_elems = @memory_sections.filter((x)->
              end = i_mem + mem
              return ((i_mem >= x.start_byte && i_mem <= x.end_byte) || (end >= x.start_byte && end <= x.end_byte) || (i_mem<=x.start_byte && x.end_byte<=end))
            )

            if busy_elems.length == 0
              cell.start_byte = i_mem
              cell.end_byte = i_mem + mem
              do cell.draw_mem
              @FREE = @FREE - cell.memory
              @memory_sections.push(cell)
              process.context.memory = mem
              mConsole.log "Процесс <span class='proc_name'>#{process.descriptor.FileName}</span>
<b>(#{process.descriptor.pid})</b> Занял <b>#{cell.memory}</b> Памяти!"
              break
            else
              min = busy_elems[busy_elems.length-1].end_byte
              for j in busy_elems
                if min>j.end_byte then min=j.end_byte
              i_mem=min+1
            if (i_mem + mem) >= @MAX
              alert "НЕДОСТАТОЧНО ПАМЯТИ"
              throw "НЕДОСТАТОЧНО ПАМЯТИ"
              break
          do @refresh
        return true
      else
        do @refresh
        return true
    else
      alert "НЕДОСТАТОЧНО ПАМЯТИ"
      throw "НЕДОСТАТОЧНО ПАМЯТИ"
      return false
  @refresh: ()->
    document.getElementById('memory_free').innerText = "#{@FREE} / #{@MAX}"
  @free: (process)->
    n=0
    while n <= @memory_sections.length-1
      i = @memory_sections[n]
      if i.pid is process.descriptor.pid
        @memory_sections[n].htmlLinks.remove()
        @memory_sections.splice(n, 1)
        mConsole.log "Процесс <span class='proc_name'>#{process.descriptor.FileName}</span>
 <b>(#{process.descriptor.pid})</b> Осовободил <b>#{process.context.memory}</b> Памяти!"
        @FREE = @FREE + process.context.memory
        do @refresh
        return
      else
        n++

#Процесс
class process
  constructor: (@descriptor, @context) ->
    if (@descriptor instanceof process_descriptor) and (@context instanceof process_context)
    else
      throw ("Контексти или дескриптор не верны!")
  refreshCommand: ()->
    line_index = @.context.CommandLine
    command = @.descriptor.command_list[line_index]
    if command
      command = split_command(command)
      @.context.Command = command.command_type

#Дескриптор процесса
class process_descriptor
  @pid = 0
  constructor: (
    @pid,
    @quantum = 0, #Квант
    @State = process_states.None, #Состояние
    @priority = process_priors.Normal, #Приоритет
    @command_list = command_list, #Список команд
    @FileName = FileName, #Имя файла процесса (Прцесс1.txt)
    @Waiting = null                       #Ожидание события
  )->
    @pid = process_descriptor.pid++


#Контекст процесса
class process_context
  constructor: (@pid) ->
    @pid #идентификатор
    @CommandLine = 0 #Счётчик команд
    @Command = "cNONE" #название текущей команды
    @CommandValue = 0 #всего квантов
    @CurrentRun = 0 #Счётчик выполненных квантов
    @memory = 0 #int количество памяти/, необходимое процессу (ПАМЯТЬ-1000) т.е. 1000 ОЗУ требуется

#Процессор
class processor
  @current_process
  @TStateProcessor = TStateProcessor.Empty
  @run: (runned_process)->
    ###if (runned_process instanceof process)###
    processor.current_process = runned_process
    processor.TStateProcessor = TStateProcessor.Busy
    document.getElementById("processor_state").innerHTML = "Занят"
    document.getElementById("processor_cur_process").innerHTML = runned_process.descriptor.FileName
    runned_process.descriptor.State = process_states.Run

    processIndexInRunned = ready_processes_stack.indexOf(runned_process)
    ready_processes_stack.splice(processIndexInRunned, 1)
    return @
  @finishCurProc: ()->
    processor.TStateProcessor = TStateProcessor.Empty
    document.getElementById("processor_state").innerHTML = processor.TStateProcessor
    document.getElementById("processor_cur_process").innerHTML = "-"
  @clearProcessor: ()->
    @TStateProcessor = TStateProcessor.Empty
    document.getElementById("processor_state").innerHTML = processor.TStateProcessor
    document.getElementById("processor_cur_process").innerHTML = "-"
    @current_process = null
  @moveProcessToReady: ()->
    processor.current_process.descriptor.State = process_states.Ready
    ready_processes_stack.push(processor.current_process)
    mConsole.log "Процесс <span class='proc_name'>#{processor.current_process.descriptor.FileName}</span>
 <b>(#{processor.current_process.descriptor.pid})</b> помещен в очередь <b>ГОТОВЫХ</b> (#{processor.current_process.context.Command})"
    draw_process processor.current_process
    do @clearProcessor

#I/O
class io
  @current_process
  @D = 1
  @CurrentStep = 0
  @CountSteps = 0
  @spooling = []
  @error = false
  @checkerror: ()->
    iorange = parseInt(document.getElementById("iorange").value)
    rng = Math.floor(Math.random()*100)
    #@fixme Тут возможно стоит делить на iorange/io.CountSteps
    if rng<=Math.floor(iorange)
      mConsole.log "Произошла <b style='color: #ff2749'>ошибка</b> <b>ввода/вывода</b>!
Процесс <span class='proc_name'>#{io.current_process.descriptor.FileName}</span> <b>(#{io.current_process.descriptor.pid})</b> аварийно завершен!"#{io.current_process.descriptor.FileName}</span> <b>(#{io.current_process.descriptor.pid})</b> аварийно завершен!"
      document.getElementById("spool_el"+io.current_process.descriptor.pid).style.backgroundColor = "#ff006a"
      @error = true
    return
  @process_error: (p)->
    console.log(p)
  @draw_spooling_process: (p)->
    text = generatePlainbyProcess p
    doc_elem = document.createElement("div")
    doc_elem.setAttribute('id', "spool_el"+p.descriptor.pid)
    doc_elem.classList.add("spooling_element")
    doc_elem.innerText = p.descriptor.pid
    ###doc_elem.setAttribute('data-tippy-content', text)###
    document.getElementById("Spooling").appendChild(doc_elem)
    tippy(doc_elem , {content: text, placement: 'top', allowHTML: true})
  @run_process: (p)->
    if (io.D is 1) #Если I/O Свободен
      io.current_process = p
      io.CurrentStep = 0
      io.CountSteps = p.context.CommandValue
      io.D = 0 #Занять I/O
      mConsole.log "Процесс <span class='proc_name'>#{p.descriptor.FileName}</span> <b>(#{p.descriptor.pid})</b> обрабатывается в соответствии с очередью <i>спуллинга</i>"
    ###else if (io.D is 0 ) #Если I/O Занят
      console.log "Ввод-Вывод занят. Ожидание"###
    return
  @tick: ()->
    if io.D is 0 #Если I/O Занят
      if (@error)
        mMemory.free io.current_process
        io.D = 1
        io.CurrentStep = 0
        io.CountSteps = 0
        ii = @spooling.indexOf(io.current_process)
        @spooling.splice(ii, 1)
        document.getElementById("spool_el"+io.current_process.descriptor.pid).remove()
        io.current_process = null
        switchTimer()
        @error = false
        return
      if (io.CountSteps>0 && io.CurrentStep >= io.CountSteps)
        io.D = 1
        io.current_process.descriptor.State = process_states.Ready
        io.current_process.context.CommandLine++
        do io.current_process.refreshCommand
        io.CurrentStep = 0
        io.CountSteps = 0
        io.current_process.descriptor.State = process_states.Ready
        ready_processes_stack.push(io.current_process)
        mConsole.log "Процесс <span class='proc_name'>#{io.current_process.descriptor.FileName}</span>
 <b>(#{io.current_process.descriptor.pid})</b> освободил <b>i/o</b> и помещен в очередь <b>ГОТОВЫХ</b>"
        draw_process io.current_process
        mConsole.log "Устройство <b>ввода/вывода</b> свободно"
        ii = @spooling.indexOf(io.current_process)
        @spooling.splice(ii, 1)
        document.getElementById("spool_el"+io.current_process.descriptor.pid).remove()
        switchTimer()

        do paintCat
        do ioRedraw
      else
        io.CurrentStep++
        do @checkerror
      do ioRedraw
      return
    if io.D is 1 #Если I/O Свободен!
      if @spooling.length is 0
        console.log(waiting_processes_stack )
        waiting_processes_stack = waiting_processes_stack.filter((element)->
          if (element.descriptor.Waiting is "paint_cat")
            return true
          else
            return false
        )
        if waiting_processes_stack.length > 0
          for n of process_priors #в обратном пордяке проходим по приоритету (от высокого к низкому)
            for value, key in waiting_processes_stack #ищим в стэке первый попавшийся по приоритету.
              if value.descriptor.priority == n
                @spooling.push value #возвращаем процесс
                p = value
                mConsole.log "Процесс <span class='proc_name'>#{p.descriptor.FileName}</span> <b>(#{p.descriptor.pid})</b> попал в <i>спуллинг</i> устройства <b>Ввода/вывода</b>"
                erase_process value.descriptor.pid
                @draw_spooling_process value
                waiting_processes_stack.splice(key, 1)
                break
        else
          debugger
          mConsole.log "Устройство <b>ввода/вывода</b> свободно, процессов не обнаружено"
          switchTimer()
      else
        if @spooling.length > 0
          io.run_process @spooling[0]
    return


#планировщик выполнения задач
class processes_dispatcher
  @new_process: (processDescriptor) ->
    if (processDescriptor instanceof process_descriptor)
      rnd = Math.floor(Math.random() * (10 - 1)) + 1
      processDescriptor.quantum = rnd
      processDescriptor.State = process_states.Ready

      context = new process_context processDescriptor.pid

      c_process = new process(processDescriptor, context)

      #считываем первую команду Память!
      command = c_process.descriptor.command_list[0]
      command = split_command(command)
      c_process.context.Command = command.command_type
      c_process.context.CommandValue = command.command_value
      mConsole.log "Запущен новый процесс <span class='proc_name'>#{c_process.descriptor.FileName}</span> с приоритетом <span class='proc_quantum'>#{c_process.descriptor.priority}</span>"
      mConsole.log "Процессу <span class='proc_name'>#{c_process.descriptor.FileName}</span> случайным образом присовоен Квант <b>#{c_process.descriptor.quantum}</b>"
      mConsole.log "Процессу <span class='proc_name'>#{c_process.descriptor.FileName}</span> присовоен Идентификатор <b>#{c_process.descriptor.pid}<b>"

      if context.Command is "ПАМЯТЬ"
#c_process.context.memory = c_process.context.CommandValue
        mMemory.use c_process, c_process.context.CommandValue
        c_process.context.CommandLine++
        #считываем вторую команду
        command = c_process.descriptor.command_list[c_process.context.CommandLine]
        command = split_command(command)
        c_process.context.Command = command.command_type
        c_process.context.CommandValue = command.command_value


      ready_processes_stack.push(c_process)
      mConsole.log "Процесс <span class='proc_name'>#{c_process.descriptor.FileName}</span> <b>(#{c_process.descriptor.pid})</b>  помещен в очередь <b>ГОТОВЫХ</b> (#{c_process.context.Command})"
      draw_process(c_process)
      return c_process
    else
      throw ("В очердь процессора добавлен не процесс!")
  @get_last_rdy_process: (sliceInStack)->
    for n of process_priors #в обратном пордяке проходим по приоритету (от высокого к низкому)
      for value, key in ready_processes_stack #ищим в стэке первый попавшийся по приоритету.
        if value.descriptor.priority == n
          return value #возвращаем процесс
  @timer_tick: ()->
    document.getElementById("processor_conext").innerText = "-"
    if processor.TStateProcessor == TStateProcessor.Empty #Если процессор проставивает то мы его нагрузим
      last_process = @get_last_rdy_process(false)

      if last_process
        processor.run last_process
        draw_process last_process
        mConsole.log "Процесс <span class='proc_name'>#{last_process.descriptor.FileName}</span>
<b>(#{last_process.descriptor.pid})</b> переведен в состояние <b>Выполнение</b> (#{last_process.context.Command})"
        return

    else
      if processor.TStateProcessor == TStateProcessor.Busy
        if processor.current_process?
          current_process = processor.current_process
          line_index = current_process.context.CommandLine
          if line_index >= current_process.descriptor.command_list.length

            processor.TStateProcessor = TStateProcessor.Empty

            mMemory.free processor.current_process
            erase_process processor.current_process.descriptor.pid
            mConsole.log "Процесс <span class='proc_name'>#{current_process.descriptor.FileName}</span>
<b>(#{current_process.descriptor.pid})</b> <span class='finished'>Завершен</span>"
            delete processor.current_process
            do processor.finishCurProc
            return


          switch (current_process.context.Command)
            when "ПАМЯТЬ"
              if (Number.isInteger(current_process.context.CommandValue))
                mMemory.use(current_process, current_process.context.CommandValue)
                current_process.context.CommandLine++
                do current_process.refreshCommand
                do processor.moveProcessToReady
              else
                alert "Недостаточно памяти!!!!"
                do processor.moveProcessToReady
# Операция переноса процесса в готовые
# moverocesstordy
            when "ПРОЦЕССОР"

              if (current_process.context.CurrentRun >= current_process.context.CommandValue)
                current_process.context.CurrentRun = 0
                current_process.context.CommandLine++
                document.getElementById("processor_conext").innerText = "-"
                do current_process.refreshCommand
                do processor.moveProcessToReady
              else
                document.getElementById("processor_conext").innerText = "#{current_process.context.CurrentRun} из #{current_process.context.CommandValue}"
                current_process.context.CurrentRun = current_process.context.CurrentRun + current_process.descriptor.quantum
                if (current_process.context.CurrentRun >= current_process.context.CommandValue)
                  current_process.context.CurrentRun = current_process.context.CommandValue
                redraw_process current_process

            when "ВВОД\\ВЫВОД"
              mConsole.log "Процесс <span class='proc_name'>#{current_process.descriptor.FileName}</span>
<b>(#{current_process.descriptor.pid})</b> переведен в состояние <b>Ожидание</b> (#{current_process.context.Command})"
              current_process.descriptor.State = process_states.Wait
              current_process.descriptor.Waiting = "paint_cat"
              waiting_processes_stack.push current_process
              console.log(waiting_processes_stack)
              do processor.clearProcessor
              draw_process current_process
              ###io.run(current_process)###
              switchTimer()

            when "КОНЕЦ"
              current_process.context.CommandLine++
              do current_process.refreshCommand
              current_process.descriptor.State = process_states.Finish
            else
              alert "неизвестная команда процессора"

          if processor.current_process? then redraw_process processor.current_process #перерисовать процессор
          return

split_command = (inCommand) ->
  command = inCommand.split('-')
  command_type = command[0].toUpperCase()
  value = parseInt(command[1])
  if (Number(value) is value && value % 1 is 0)
    return {command_type: command_type, command_value: value}
  else
    return {command_type: command_type, command_value: null}

###################################
paintCat = ()->
  input = document.getElementById("inputoutput_device")
  t = document.createElement('img');
  rnd = Math.floor(Math.random() * (img_cats.length - 1)) + 1
  if !rnd then alert "ERRRRRRRRRROR"
  t.src = "img/cats/" + img_cats[rnd];
  t.classList.add('cat')
  t.classList.add('cat_fly')
  input.prepend(t);
  setTimeout(=>
    t.remove()
  , 3000)

erase_process = (pid) ->
  element = document.querySelector "div[data-processid=\"#{pid}\"]"
  element.classList.add('hide');
  window.setTimeout((->
    element?.remove()
  ), 350);

redraw_process = (in_process) ->
  element = document.querySelector "div[data-processid=\"#{in_process.descriptor.pid}\"] "
  text = generateHTMLbyProcess(in_process)
  if in_process.descriptor.State is process_states.Finish
    element.classList.add('finished')
  element.innerHTML = text

draw_process = (in_process) ->
  switch (in_process.descriptor.State)
    when process_states.Ready then columnId = "ready_column"
    when process_states.Run then columnId = "runing_column"
    when process_states.Wait then columnId = "waiting_column"
    else
      columnId = null
  if columnId
    oldestElement = document.querySelector "div[data-processid=\"#{in_process.descriptor.pid}\"]"
    if oldestElement
      oldestElement.classList.add('hide-to-left', 'hide');
      window.setTimeout((->
        oldestElement?.remove()
      ), 350);

    text = generateHTMLbyProcess(in_process)

    t = document.createElement('div');
    t.setAttribute('data-processid', in_process.descriptor.pid)
    t.className = "view_process"
    t.innerHTML = text
    document.getElementById(columnId).appendChild(t)

generateHTMLbyProcess = (process) ->
  context_text = ""
  descriptor_text = ""
  for key, value of process.context
    value = if (value?) then value.toString() else "none"
    context_text += "#{key.toString()} : #{value.toString()}<br/>"

  if (process.context.Command == process_comands.PROCESSOR and process.context.CommandValue? and process.context.CurrentRun?)
    context_text += "<progress max=\"#{process.context.CommandValue}\" value=\"#{process.context.CurrentRun }\"></progress>"

  for key, value of process.descriptor
    if key is 'command_list' then continue
    value = if (value?) then value.toString() else "none"
    descriptor_text += "<div>#{key.toString()} : #{value.toString()}</div>"

  text = descriptor_text + "<div class='context'>Контекст: <div>#{context_text}</div></div>"
  return text

generatePlainbyProcess = (process) ->
  context_text = "Контекст:<br/>"
  descriptor_text = "Дескриптор:<br/>"
  for key, value of process.context
    value = if (value?) then value.toString() else "none"
    context_text += "#{key.toString()} : #{value.toString()} | "

  for key, value of process.descriptor
    if key is 'command_list' then continue
    value = if (value?) then value.toString() else "none"
    descriptor_text += "#{key.toString()} : #{value.toString()} | "

  text = descriptor_text + "<br/>" + context_text
  return text

ioRedraw = () ->
  if io.D is 1
    status = "Свободно"
    document.getElementById("inputoutput_device_process").innerText = "-"
    document.getElementById("inputoutput_device_name").innerText = "-"
    document.getElementById("inputoutput_device_pid").innerText = "-"
  else
    status = "Работает"
    document.getElementById("inputoutput_device_process").innerText = "#{io.CurrentStep} из #{io.CountSteps}"
    document.getElementById("inputoutput_device_name").innerText = io.current_process.descriptor.FileName
    document.getElementById("inputoutput_device_pid").innerText = io.current_process.descriptor.pid

  document.getElementById("inputoutput_device_state").innerText = status

  return

###################################
#### Блок отвечающий за UI ########
###################################
generateSelectTags = ()->
  process_priors_select_text = "<select name=\"process_prior\">";
  for key, val of process_priors
    process_priors_select_text += "<option value=\"#{key}\">#{val}</option>"
  process_priors_select_text += "</select>"
  return process_priors_select_text


openTab = (evt, dataname) ->
  tabcontent = document.getElementsByClassName("process");
  for i in tabcontent
    i.style.display = "none"
  tablinks = document.getElementsByClassName("tablinks");
  for j in tablinks
    j.className = j.className.replace(" active", "");
  processes = document.querySelectorAll(".process[data-processname=\"#{dataname}\"]");
  for n in processes
    n.style.display = "flex"
  evt.currentTarget.className += " active";
  return

createProcessTab = (f) ->
  tablesWrap = document.getElementById "prcoessTextFromFileTabs"
  tableW = tablesWrap.querySelector(".process[data-processname=\"#{f.name}\"]")
  #Если такой вкладки нет
  if !tableW?
##Генерируем вкладку для управления и запуска процесса
    tableWrap = document.createElement "div" ##обертка для группы элементов интерфейса
    table = document.createElement "table" ##Таблица с перечислением команд из файлов
    processinfo = document.createElement "div" ##Динамическая информация о процесса
    runButton = document.createElement "button" ##Кнопка запустить

    #Создаем отрисовку для процессов
    tableWrap.setAttribute "data-processname", f.name
    tableWrap.className = "process"
    tablesWrap.appendChild tableWrap
    tableWrap.appendChild table

    runButton.className = "runProcessButton"
    runButton.innerText = "Добавить процесс в очередь"
    runButton.addEventListener "click", (e)->
      select = e.target.parentElement.querySelector("select[name=\"process_prior\"]")
      process_name = e.target.parentElement.parentElement.getAttribute('data-processname')
      select_value = select.value

      ###определяем лист команд###
      commandListTD = Array.from document.getElementById("prcoessTextFromFileTabs").querySelectorAll("div[data-processname=\"#{process_name}\"] table tbody tr td")

      commandList = commandListTD.map((item)->  item.innerText)
      processDescriptor = new process_descriptor null, 1, "None", select_value, commandList, f.name
      pr = processes_dispatcher.new_process(processDescriptor)

      @

    ##Создает кнопку для вкладок процессов
    btnsWrap = document.getElementById "processesTabsBtns"
    btn = document.createElement "button"
    btn.className = "tablinks"
    btn.innerText = f.name
    btn.addEventListener "click", (e)->openTab(e, f.name)
    btnsWrap.appendChild btn

    selecttags = do generateSelectTags
    processinfo.innerHTML = "<div >Приоритет: #{selecttags}</div>"
    processinfo.appendChild runButton
    tableWrap.appendChild processinfo

  else
    table = tableW.getElementsByTagName("table")
    btns = document.querySelectorAll(".tab .tablinks")
    for b in btns
      if (b.textContent.includes(f.name))
        btn = b
        break

  openTab {currentTarget: btn}, f.name

  reader = new FileReader()
  reader.onload = (theFile) ->
    contents = theFile.currentTarget.result
    lines = contents.split('\n')
    for s in lines by -1
      s = do s.trim
      if (s? and s.length > 0)
        row = table.insertRow(0);
        cell1 = row.insertCell(0);
        cell1.innerHTML = s;
  reader.readAsText f, "CP1251" #Подгрузка файла как текст с Кодировкой Windows-1251

handleFileSelect = (evt) ->
  files = evt.target.files

  if Array.isArray files
    for f in files
      createProcessTab f
      mConsole.log "Процесс <span class='proc_name'>#{f.name}</span> инициализирован!"
  else
    createProcessTab files[0]
    mConsole.log "Процесс <span class='proc_name'>#{files[0].name}</span> инициализирован!"
  return

window.onload = ->
  fileInput = document.getElementById('fileInput')
  fileInput.addEventListener 'change', handleFileSelect, false
  do mMemory.refresh
  mConsole.log "Модель процессора подготовлена"
  mConsole.log "Модель устройства ввода/вывода подготовлена"

  consoleFullSizeBtn = document.querySelector('#console_wrap>button')
  consoleFullSizeBtn.addEventListener "click", ()->
    wrap = document.getElementById("console_wrap")
    if (wrap.classList.contains("full-sized"))
      wrap.classList.remove "full-sized"
    else
      wrap.classList.add "full-sized"
    return

####Таймеры####
ioTimer = {} ## таймер ввыода вывода
processTimer = {} #Таймер процессора
processTimerRunned = false
lastStartedTimer = null
processorStartButton = document.getElementById('processor_start')
tick = 0;
timerRunned = false;
switchTimer = ()=>
  if (lastStartedTimer == processTimer)
    processTimer.stop()
    lastStartedTimer = ioTimer
    ioTimer.run()
  else
    ioTimer.stop()
    lastStartedTimer = processTimer
    processTimer.run()

class processTimer
  @running = false
  @interval = {}
  @wrap = document.getElementById("processor")
  @run: () ->
    @interval = setInterval((->
      progressbar = document.getElementById("tick_progress")
      if progressbar.value is 2000
        progressbar.value = 0
        tick++;
        do processes_dispatcher.timer_tick
      else
        progressbar.value = progressbar.value + 20
      return
    ), 5)
    @running = true
    @wrap.classList.remove('disabled')
  @stop: ()->
    clearInterval @interval
    @running = false
    @wrap.classList.add('disabled')

class ioTimer extends processTimer
  @wrap = document.getElementById("io_wrap")
  @run: () ->
    @interval = setInterval((->
      progressbar = document.getElementById("tick_progress_io")
      if progressbar.value is progressbar.max
        progressbar.value = 0
        tick++;
        do io.tick
      else
      progressbar.value = progressbar.value + 50
      return
    ), 6)
    @running = true
    @wrap.classList.remove('disabled')

processorStartButton.addEventListener "click", (e)->
  if (!timerRunned)
    if (!lastStartedTimer) then lastStartedTimer = processTimer
    timerRunned = true
    e.target.innerHTML = "Остановить планировщик"
    lastStartedTimer.run()
    return
  else
    timerRunned = false
    lastStartedTimer.stop()
    e.target.innerHTML = "Запустить планировщик"
    return


iorange = document.getElementById('iorange')
listener = ->
  window.requestAnimationFrame ->
    document.getElementById('range-val').innerHTML = iorange.value + "%"
    return
  return
iorange.addEventListener 'mousedown', ->
  listener()
  iorange.addEventListener 'mousemove', listener
  return
iorange.addEventListener 'mouseup', ->
  iorange.removeEventListener 'mousemove', listener
  return
iorange.addEventListener 'keydown', listener
