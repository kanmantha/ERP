using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using ErpApp.Data;
using ErpApp.Models;

namespace ErpApp.Controllers
{
    public class ProcurementsController : Controller
    {
        private readonly ApplicationDbContext _context;

        public ProcurementsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: Procurements
        public async Task<IActionResult> Index()
        {
            return View(await _context.Procurements.ToListAsync());
        }

        // GET: Procurements/Details/5
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var procurement = await _context.Procurements
                .FirstOrDefaultAsync(m => m.Id == id);
            if (procurement == null)
            {
                return NotFound();
            }

            return View(procurement);
        }

        // GET: Procurements/Create
        public IActionResult Create()
        {
            return View();
        }

        // POST: Procurements/Create
        // To protect from overposting attacks, enable the specific properties you want to bind to.
        // For more details, see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([Bind("Id,ItemName,Quantity,UnitPrice,OrderDate,Supplier,Status")] Procurement procurement)
        {
            if (ModelState.IsValid)
            {
                _context.Add(procurement);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }
            return View(procurement);
        }

        // GET: Procurements/Edit/5
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var procurement = await _context.Procurements.FindAsync(id);
            if (procurement == null)
            {
                return NotFound();
            }
            return View(procurement);
        }

        // POST: Procurements/Edit/5
        // To protect from overposting attacks, enable the specific properties you want to bind to.
        // For more details, see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, [Bind("Id,ItemName,Quantity,UnitPrice,OrderDate,Supplier,Status")] Procurement procurement)
        {
            if (id != procurement.Id)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                try
                {
                    _context.Update(procurement);
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!ProcurementExists(procurement.Id))
                    {
                        return NotFound();
                    }
                    else
                    {
                        throw;
                    }
                }
                return RedirectToAction(nameof(Index));
            }
            return View(procurement);
        }

        // GET: Procurements/Delete/5
        public async Task<IActionResult> Delete(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var procurement = await _context.Procurements
                .FirstOrDefaultAsync(m => m.Id == id);
            if (procurement == null)
            {
                return NotFound();
            }

            return View(procurement);
        }

        // POST: Procurements/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var procurement = await _context.Procurements.FindAsync(id);
            if (procurement != null)
            {
                _context.Procurements.Remove(procurement);
            }

            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        private bool ProcurementExists(int id)
        {
            return _context.Procurements.Any(e => e.Id == id);
        }
    }
}
