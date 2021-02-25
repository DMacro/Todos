
require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret,'secret'
end

helpers do

  def sort_lists(lists, &block)

    complete_lists, incomplete_lists = lists.partition{|list| list_complete?(list)}

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }

  end
  
  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition{|todo| todo[:completed]}

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end

  def list_complete?(list)
    list_count(list) > 0 && list_remaining(list)  == 0
  end

  def list_class(list)
    "complete" if list_complete?(list) 
  end
  
  def list_count(list) 
    list[:todos].size
  end

  def list_remaining(list) 
    list[:todos].select {|todo| !todo[:completed]}.size
  end

  def list_as_fraction(list)
    a = list_remaining (list)
    b = list_count (list)
    "#{a} / #{b}"
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Renders the new list form
get "/lists/new" do
  erb :new_lists, layout: :layout
end

# Returns message if the name is invalid.
def error_for_list_name(name)
  if session[:lists].any? {|list| list[:name] == name}
    "The list name must be unique!"
  elsif !(1..100).cover? name.size 
    "The list name must contain between 1 and 100 characters!"
  end
end

# Returns message if the name is invalid.
def error_for_todo(name)
  if !(1..100).cover? name.size 
    "Todo must contain between 1 and 100 characters!"
  end
end

# Create a new list
post "/lists" do
  
  list_name = params[:list_name].strip
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_lists, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list was created successfully" 
    redirect "/lists"
  end
end

# Renders the todo item from list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

# Edit an exiting todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit_list, layout: :layout
end

# Update an exiting todo list name
post "/lists/:id" do
  
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = session[:lists][id]
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated." 
    redirect "/lists/#{id}"
  end
end

# Removing an exiting todo list
post "/list/:id/destroy" do

  id = params[:id].to_i
  element = session[:lists].delete_at(id)
  
    session[:success] = "The list '#{element[:name]}' has been Destroyed." 
    redirect "/lists"

end


# Add todo to a list

post "/lists/:list_id/todos" do
  
  todo_name = params[:todo].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  
  error = error_for_todo(todo_name)
    if error
      erb :list, layout: :layout
    else
      @list[:todos] << {name: todo_name, completed: false}
      session[:success] = "The todo was added" 
      redirect "/lists/#{@list_id}"
    end
end

# Removing an exiting todo
post "/list/:list_id/todos/:todo_id/destroy" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  @list = session[:lists][list_id]
  element = @list[:todos].delete_at(todo_id)
    session[:success] = "The todo '#{element[:name]}' has been destroyed." 
    redirect "/lists/#{list_id}"

end

# Update Status of a todo
post "/list/:list_id/todos/:todo_id" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  @list = session[:lists][list_id]

  @todo = @list[:todos][todo_id]
  p params[:completed]
  is_completed = params[:completed] == "true"
  @todo[:completed] = is_completed
    session[:success] = "The todo '#{@todo[:name]}' has been updated." 
    p @todo[:completed]
    redirect "/lists/#{list_id}"
end


# Sets all todos to completed for a  list
post "/list/:id/complete_all" do
  
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each{|todo| todo[:completed] = true}

    session[:success] = "All todos for the '#{@list[:name]}' list have been completed." 
    redirect "/lists/#{@list_id}"

end

