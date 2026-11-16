books = [
  [ "Pride and Prejudice", "Jane Austen", 1813, "Elizabeth Bennet, Mr Darcy, and the cost of first impressions." ],
  [ "Frankenstein", "Mary Shelley", 1818, "A scientist builds a creature and abandons it." ],
  [ "Moby-Dick", "Herman Melville", 1851, "Captain Ahab hunts the white whale." ],
  [ "Great Expectations", "Charles Dickens", 1861, "Pip rises from the marshes to London and back." ],
  [ "Middlemarch", "George Eliot", 1871, "Life and ambition in a provincial English town." ],
  [ "The Adventures of Huckleberry Finn", "Mark Twain", 1884, "Huck and Jim float down the Mississippi." ],
  [ "Dracula", "Bram Stoker", 1897, "A count comes to England, told in letters and diaries." ],
  [ "The Call of the Wild", "Jack London", 1903, "A sled dog returns to his instincts in the Yukon." ],
  [ "A Room with a View", "E. M. Forster", 1908, "Lucy Honeychurch chooses between propriety and love." ],
  [ "The Great Gatsby", "F. Scott Fitzgerald", 1925, "Money, longing, and a green light across the bay." ]
]

books.each do |title, author, year, summary|
  Book.find_or_create_by!(title:, author:) { |book| book.update!(year:, summary:) }
end
