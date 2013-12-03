module ReadOnlyModels
  
  # Prevent creation of new records and modification to existing records
  def readonly?
    return true
  end
 
  # Prevent objects from being destroyed
  def before_destroy
    raise ActiveRecord::ReadOnlyRecord
  end
  
  def destroy
    raise ActiveRecord::ReadOnlyRecord
    false
  end
  
end