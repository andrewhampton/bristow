class Bristow::Termination
  def continue?(messages)
    raise NotImplementedError, "`#continue?` must be implemented in #{self.class}"
  end
end
