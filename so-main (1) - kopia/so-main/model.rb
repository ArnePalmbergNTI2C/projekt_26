require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require './model.rb'
require 'sinatra/flash'

enable :sessions

def db_hash()
    
  db = SQLite3::Database.new('db/todo2021.db')
  db.results_as_hash = true

  return db

end

def db()
    
  db = SQLite3::Database.new('db/todo2021.db')

  return db
  
end

#skapa användare

def anvandarnamnet_inte_tomt_skapa(username)
    
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == "" or password_confirm == ""

    flash[:notice] = "Lösenordet kan inte vara tomt"
    redirect('/inlogg')

  else

    password_not_empty_skapa_anvandare(username,password,password_confirm)

  end

end

def password_not_empty_skapa_anvandare(username,password,password_confirm)
    

  db = db_hash

  result = nil
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first

  if result == nil

    nytt_anvandar_namn(username,password,password_confirm)

  else
    
    flash[:notice] = "Användarnamnet finns redan"
    redirect('/inlogg')

  end

end

def nytt_anvandar_namn(username,password,password_confirm)
    
  if password == password_confirm

    right_password_skapa_anvandare(username,password)

  else
    flash[:notice] = "Lösenorden matchade inte"
    redirect('/inlogg')

  end

end

def right_password_skapa_anvandare(username,password)
    
  password_digest = BCrypt::Password.create(password)
  
  db = db_hash

  db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",[username,password_digest])
  
  flash[:notice] = "Användare skapad"
  redirect('/inlogg')

end

#logga in i användare

def anvandarnamnet_inte_tomt_logga_in(username)
    
  password = params[:password]

  if password == ""

    flash[:notice] = "Lösenordet kan inte vara tomt"
    redirect('/inlogg')

  else

    password_not_empty_logga_in_anvandare(username,password)

  end

end

def password_not_empty_logga_in_anvandare(username,password)
    
  db = db_hash

  result = db.execute("SELECT * FROM users WHERE username = ?",username).first

  if result != nil
      
    right_anvandar_name_logg_in(username,password,result)

  else

    flash[:notice] = "Finns ingen användare med detta namn"
    redirect('/inlogg')

  end

end

def right_anvandar_name_logg_in(username,password,result)
    
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password

    right_password_logg_in_anvandare(id,username)
  else
    
    flash[:notice] = "Fel lösenord"
    redirect('/inlogg')

  end

end

def right_password_logg_in_anvandare(id,username)
    
  session[:id_username] = id
  session[:username] = username

  flash[:notice] = "Du har blivit inloggad!"
  session[:logged_in_a] = true
  redirect('/startsida')

end

#skapa familjekonto

def familje_namnet_inte_tomt_skapa(familj_namn)
    
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == "" or password_confirm == ""
    flash[:notice] = "Lösenordet kan inte vara tomt"
    redirect('/inlogg')

  else

    password_not_empty_skapa_familj(familj_namn,password,password_confirm)

  end

end

def password_not_empty_skapa_familj(familj_namn,password,password_confirm)
    
  db = db_hash()

  result = nil
  result = db.execute("SELECT * FROM familj WHERE familj_namn = ?",familj_namn).first

  if result == nil

    nytt_familje_namn(familj_namn,password,password_confirm)

  else

    flash[:notice] = "Familjenamnet finns redan"
    redirect('/inlogg')


  end

end

def nytt_familje_namn(familj_namn,password,password_confirm)
    
  if password == password_confirm

    right_password_skapa_familj(familj_namn,password,password_confirm)

  else
    flash[:notice] = "Lösenorden matchade inte"
    redirect('/inlogg')

  end

end

def right_password_skapa_familj(familj_namn,password,password_confirm)
    
  password_digest = BCrypt::Password.create(password)

  db = db()

  db.execute("INSERT INTO familj (familj_namn,pwdigest) VALUES (?,?)",[familj_namn,password_digest])
  
  flash[:notice] = "Familj skapad. Du är admin för familjen"
  redirect('/inlogg')

end

#logga in i familj

def familje_namnet_inte_tomt_logg_in(familj_namn)
    
  password = params[:password]

  if password == ""

    flash[:notice] = "Lösenordet kan inte vara tomt"
    redirect('/inlogg')
    
  else

    password_not_empty_logg_in_familj(familj_namn,password)

  end

end

def password_not_empty_logg_in_familj(familj_namn,password)
    
  db = db_hash()

  result = db.execute("SELECT * FROM familj WHERE familj_namn = ?",[familj_namn]).first
  
  if result != nil
        
    right_familj_name_logg_in(familj_namn,password,result)

  else

    flash[:notice] = "Finns ingen familj med detta familjenamn"
    redirect('/inlogg')

  end

end

def right_familj_name_logg_in(familj_namn,password,result)
    
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password

    right_password_logg_in_familj(familj_namn,id)

  else
    flash[:notice] = "Fel lösenord"
    redirect('/inlogg')
    
  end

end


def right_password_logg_in_familj(familj_namn,id)
    

  id2 = session[:id_username]


  if id2 == nil

    flash[:notice] = "Du måste vara inloggad som en person först"
    redirect('/inlogg')

  else
  
    om_inloggad_logg_in_familj(familj_namn,id,id2)
  end

end

def om_inloggad_logg_in_familj(familj_namn,id,id2)

  session[:familj_id] = id
  familj_id = id
  session[:familj_namn] = familj_namn
  session[:startsida_text_familj] = "i familj #{familj_namn}"

  db = db_hash

  result = db.execute("SELECT * FROM familj_users WHERE user_id = ?",id2).first
  if result == nil
    db.execute("INSERT INTO familj_users (admin_normal,user_id,familj_id) VALUES (?,?,?)",[0,id2, id])
  else

    db = db()

    result = db.execute("SELECT familj_id FROM familj_users WHERE user_id = ?",id2).first

    result = result[0]

    if result != familj_id
      flash[:notice] = "Du kan inte vara med i två familjer samtidigt. Radera dig från den familj du är inlogg i på familj sidan"
      redirect('/inlogg')

    end

  end
         
  result = db.execute("SELECT * FROM familj_users WHERE familj_id = ?",id)
  idd = session[:id_username]

  if result.length == 1

    db.execute("UPDATE familj_users SET admin_normal=? WHERE familj_id = ?",[1, id])

  else

    result = db.execute("SELECT admin_normal FROM familj_users WHERE user_id = ?",idd)

    result = result[0][0]
  
    if result != 1

      db.execute("UPDATE familj_users SET admin_normal=? WHERE user_id = ?",[0, idd])

    end

  end

  id = session[:id_username]

  db = db()
  result = db.execute("SELECT admin_normal FROM familj_users WHERE user_id = ?",id)
  result = result[0][0]

  if result == 1
    session[:admin] = true
  else
    session[:admin] = false
  end
    
  flash[:notice] = "Du har blivit inloggad i en familj!"
  session[:logged_in_f] = true

  redirect('/startsida')

end