require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require './model.rb'
require 'sinatra/flash'

enable :sessions

before do
  
  restricted_paths = ['/inkopslista','/familj']
  restricted_paths_2 = ['/familj']

  if !session[:logged_in_a] && restricted_paths.include?(request.path_info)   #alternativt session[:id] != nil...
    flash[:notice] = "Du är inte inloggad som en användare"
    redirect '/startsida'
  end

  if !session[:logged_in_f] && restricted_paths_2.include?(request.path_info)   #alternativt session[:id] != nil...
    flash[:notice] = "Du är inte inloggad i en familj"
    redirect '/startsida'
  end

  if session[:logged_in_f] && !session[:admin] && request.path_info == '/familj/settings'
    flash[:notice] = "Du är inte admin"
    redirect '/familj'
  end
 

end

get('/startsida') do

  slim(:index)

end

get('/inlogg') do

  slim(:"inlogg/index")

end

#skapa användare
post('/users_new') do

  username = params[:username]

  if username == ""
    flash[:notice] = "Användarnamnet kan inte vara tomt"
    redirect('/inlogg')  
  else

    anvandarnamnet_inte_tomt_skapa(username)

  end
end

#logga in i användare
post('/login_user') do 

  #om använderen inte finns

  session[:familj_namn] = nil
  session[:startsida_text_familj] = nil
  session[:familj_id] = nil

  username = params[:username]

  if username == ""

    flash[:notice] = "Användarnamnet kan inte vara tomt"
    redirect('/inlogg')
  else
  
    anvandarnamnet_inte_tomt_logga_in(username)

  end

end

#skapa familjekonto
post('/familj_new') do

  familj_namn = params[:family_name]
  
  if familj_namn == ""

    flash[:notice] = "Familjenamnet kan inte vara tomt"
    redirect('/inlogg')

  else
    
    familje_namnet_inte_tomt_skapa(familj_namn)

  end
end

#logga in i familj
post('/login_familj') do 

  familj_namn = params[:family_name]

  if familj_namn == ""

    flash[:notice] = "Familjenamnet kan inte vara tomt"
    redirect('/inlogg')

    
  else

    familje_namnet_inte_tomt_logg_in(familj_namn)

  end


end

post('/utlogg') do

  session[:username] = nil
  session[:id_username] = nil
  session[:familj_namn] = nil
  session[:startsida_text_familj] = nil
  session[:familj_id] = nil
  session[:admin] = false
  session[:logged_in_a] = false
  session[:logged_in_f] = false
  
  flash[:notice] = "Du har blivit utloggad!"
  redirect('/startsida')

end

#inköpslista

get('/inkopslista') do

  id = session[:id_username]

  db = db_hash()

  result = db.execute("SELECT * FROM todos WHERE user_id = ?",id)
  slim(:"inkopslista/index",locals:{todos:result})

end

post('/inkopslista/:id/delete') do

  id = params[:id].to_i

  db = db()

  db.execute("DELETE FROM todos WHERE todo_id = ?",id)
  redirect("/inkopslista")

end

get('/inkopslista/:id/edit') do

  id = params[:id].to_i

  db = db_hash()

  result = db.execute("SELECT * FROM todos WHERE todo_id = ?",id).first
  slim(:"/inkopslista/edit", locals:{result:result})

end

post('/inkopslista/:id/update') do

  id = params[:id].to_i
  lista = params[:title]
  user_id = params[:user_id].to_i

  db = db()

  db.execute("UPDATE todos SET lista=?,user_id=? WHERE todo_id = ?",[lista,user_id,id])
  redirect('/inkopslista')
  
end

post('/inkopslista') do

  title = params[:title]
  user_id = session[:id_username]

  if user_id == nil
        
    "Inte inloggad"

  else

    db = db()

    db.execute("INSERT INTO todos (lista, user_id) Values (?,?)",[title, user_id])
    redirect('/inkopslista')

  end
 
end

#inne i listorna i inköpslisorna

post('/inkopslista/:id/:idd/delete') do

  id = params[:id].to_i
  idd = params[:idd].to_i

  db = db()

  db.execute("DELETE FROM egna_listor WHERE todo_id = ?",idd)
  redirect("/inkopslista/#{id}")

end

get('/inkopslista/:id/:idd/edit') do
  id = params[:idd].to_i

  db = db_hash()

  result = db.execute("SELECT * FROM egna_listor WHERE todo_id = ?",id).first
  slim(:"/inkopslista/inne/edit", locals:{result:result})

end


post('/inkopslista/:id/:idd/update') do

  id = params[:id].to_i
  idd = params[:idd].to_i
  content = params[:title]
  user_id = params[:user_id].to_i

  db = db()

  db.execute("UPDATE egna_listor SET content=?,id=? WHERE todo_id = ?",[content,user_id,idd])
  redirect("/inkopslista/#{id}")
  
end

post('/inkopslista_tillbaka') do

  redirect("/inkopslista")

end

get('/inkopslista/:id') do

  id = params[:id].to_i
  session[:idd] = id

  db = db_hash()

  result = db.execute("SELECT * FROM egna_listor WHERE id = ?",id)
  slim(:"inkopslista/show",locals:{egna_listor:result})

end

post('/inkopslista/:id/new') do

  id = params[:id].to_i
  content = params[:title]

  db = db()

  db.execute("INSERT INTO egna_listor (id, content) Values (?,?)",[id, content])
  redirect("/inkopslista/#{id}")

end

#familj sidan
get('/familj') do

  familj_id = session[:familj_id]


  db = db_hash()
  
  result = db.execute("SELECT users.username,admin_normal,familj_users.user_id FROM familj_users INNER JOIN users ON familj_users.user_id = users.id WHERE familj_id = ?", familj_id)
  slim(:"familj/index",locals:{familj_users:result})

end

get('/familj/settings') do

  familj_id = session[:familj_id]

  db = db_hash()
  
  result = db.execute("SELECT users.username,admin_normal,familj_users.user_id FROM familj_users INNER JOIN users ON familj_users.user_id = users.id WHERE familj_id = ?", familj_id)
  slim(:"familj/settings/index",locals:{familj_users:result})

end

post('/familj_settings_tillbaka') do

  redirect("/familj")

end

post('/familj/settings/:id/delete') do

  id = params[:id].to_i

  db = db()

  if id == session[:id_username]
    
    flash[:notice] = "Du kan inte ta bort dig själv här"
    redirect("/familj/settings")

  else

    db.execute("DELETE FROM familj_users WHERE user_id = ?",id)
    redirect("/familj/settings")
  end

end

post('/familj/settings/:id/update') do

  id = params[:id].to_i
  familj_id = session[:familj_id]

  db = db()

  db.execute("UPDATE familj_users SET admin_normal=? WHERE admin_normal = ? AND familj_id = ?",[0,1, familj_id]).first
  db.execute("UPDATE familj_users SET admin_normal=? WHERE user_id = ?",[1,id])
  session[:admin] = false


  redirect("/familj")
  
end

post('/familj/:id/delete') do


  id = params[:id].to_i
  familj_id = session[:familj_id]

  db = db()

  db.execute("DELETE FROM familj_users WHERE user_id = ?",id)


  if session[:admin] = true    

    result = db.execute("SELECT user_id FROM familj_users WHERE familj_id = ?", familj_id)

    result = result[0][0]
    db.execute("UPDATE familj_users SET admin_normal=? WHERE user_id = ?",[1, result]).first

    session[:admin] = false

  end

  session[:familj_namn] = nil
  session[:startsida_text_familj] = nil
  session[:familj_id] = nil
  session[:logged_in_f] = false
  
  flash[:notice] = "Du har raderats från familjen"

  redirect("/startsida")
  

end