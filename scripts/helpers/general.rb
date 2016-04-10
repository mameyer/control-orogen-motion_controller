#! /usr/bin/env ruby

@inSim = true
# Defines which kind of slam shuld be used, graph_slam or slam3d.
@use_slam3d = false

class TaskStruct
    attr_accessor :name
    attr_accessor :task
    attr_accessor :config

    def initialize()
        @config = Array.new
        @config << "default"
    end
end

def getTask(name, taskArray = nil)
    task = Orocos.name_service.get name
    if(taskArray)
        struct = TaskStruct.new()
        struct.name = name
        struct.task = task
        taskArray << struct
    end
    task
end

def addConfig(task, config, taskArray)
    
    searchedStruct = nil
    #this is slow, but we don't care for now...
    taskArray.each do |struct|
        if(task == struct.task)
            searchedStruct = struct
            break;
        end
    end
    
    if(!searchedStruct)
        raise("Task #{taks} is not registered")
    end
    
    searchedStruct.config << config
end

def setAllConfigs(taskArray)
    taskArray.each do |struct|
        puts("Applying config #{struct.config} to task #{struct.name}")
        Orocos.conf.apply(struct.task, struct.config, true)
    end
end

def setupAllTransformers(taskArray)
    taskArray.each do |struct|
        puts("Setting up Transformer for #{struct.name}")
        Bundles.transformer.setup(struct.task)
    end
end

def configureAll(taskArray)
    taskArray.each do |struct|
        puts("Configuring Task #{struct.name}")
        struct.task.configure()
    end
end

def startAll(taskArray)
    taskArray.each do |struct|
        puts("Starting Task #{struct.name}")
        struct.task.start()
    end
end

def wait_for(task_context, state)
    loop = true
    while loop
      if task_context.state == state
          puts "#{task_context.name}: state #{task_context.state} entered"
          loop = false
      end
      sleep(0.01)
    end
end

def task_in_exception(task)
  if(task.exception?)
    puts "Task #{task.name} is in exception state and will be restarted"
    task.reset_exception
  else 
    return false
  end

  if(task.running?)
    task.stop
  end

  if(task.ready?)
    task.cleanup
  end
  
  task.configure
  task.start
  
  puts "Task #{task.name} has been restarted"
  return true
end

def start_task(task)
    if not task.running? 
        task.configure
        task.start
    end
end

def stop_task(task)
    if task.running?
        task.stop
        wait_for(task, :STOPPED)
    end
    
    if task.ready?
        task.cleanup
        wait_for(task, :PRE_OPERATIONAL)
    end
end

def restart(task)
    if(task.exception?)
        task.reset_exception
    end
    if task.running?
	    stop_task(task)
    end
    start_task(task)
    wait_for(task, :RUNNING)
end

def try_to_get_task(task_name, exit_on_failure=false)
    task = nil
    begin
        task = Orocos.name_service.get task_name
        puts "\n Task #{task_name} found"
    rescue Exception => e
        puts e.message
        puts "\nCould not find task #{task_name}. Retry (y/n)?"
        ret = $stdin.gets.chomp
        if(ret == 'y')
            return try_to_get_task(task_name)
        else
            if exit_on_failure
                exit(-1)
            end
            return nil
        end
    end
    return task
end

